require "forwardable"
require "concurrent/timer_task"
require "concurrent/executor/fixed_thread_pool"
require "flipper/cloud/telemetry/metric"
require "flipper/cloud/telemetry/metric_storage"

module Flipper
  module Cloud
    class Telemetry
      extend Forwardable

      # Internal: Map of instances of telemetry.
      def self.instances
        @instances ||= Concurrent::Map.new
      end
      private_class_method :instances

      def self.reset
        instances.each { |_, instance| instance.stop }.clear
      end

      # Internal: Fetch an instance of telemetry once per process per url +
      # token (aka cloud endpoint). Should only ever be one instance unless you
      # are doing some funky stuff.
      def self.instance_for(cloud_configuration)
        instances.compute_if_absent(cloud_configuration.url + cloud_configuration.token) do
          new(cloud_configuration)
        end
      end

      attr_reader :cloud_configuration, :metric_storage, :pool, :timer

      def_delegator :@cloud_configuration, :telemetry_logger, :logger

      def initialize(cloud_configuration)
        @pid = $$
        @cloud_configuration = cloud_configuration
        start
        at_exit { stop }
      end

      # Public: Records telemetry events based on active support notifications.
      def record(name, payload)
        return unless name == Flipper::Feature::InstrumentationName
        return unless payload[:operation] == :enabled?
        detect_forking

        metric = Metric.new(payload[:feature_name].to_s.freeze, payload[:result])
        @metric_storage.increment metric
      end

      # Start all the tasks and setup new metric storage.
      def start
        logger.info "name=flipper_telemetry action=start"

        @metric_storage = MetricStorage.new

        @pool = Concurrent::FixedThreadPool.new(2, {
          max_queue: 5,
          fallback_policy: :discard,
          name: "flipper-telemetry-post-to-cloud-pool".freeze,
        })

        @timer = Concurrent::TimerTask.execute({
          execution_interval: @cloud_configuration.telemetry_interval,
          name: "flipper-telemetry-post-to-pool-timer".freeze,
        }) { post_to_pool }
      end

      # Shuts down all the tasks and tries to flush any remaining info to Cloud.
      def stop
        logger.info "name=flipper_telemetry action=stop"

        if @timer
          logger.debug "name=flipper_telemetry action=timer_shutdown_start"
          @timer.shutdown
          # no need to wait long for timer, all it does is drain in memory metric
          # storage and post to the pool of background workers
          timer_termination_result = @timer.wait_for_termination(1)
          @timer.kill unless timer_termination_result
          logger.debug "name=flipper_telemetry action=timer_shutdown_end result=#{timer_termination_result}"
        end

        if @pool
          post_to_pool # one last drain
          logger.debug "name=flipper_telemetry action=pool_shutdown_start"
          @pool.shutdown
          pool_termination_result = @pool.wait_for_termination(@cloud_configuration.telemetry_shutdown_timeout)
          @pool.kill unless pool_termination_result
          logger.debug "name=flipper_telemetry action=pool_shutdown_end result=#{pool_termination_result}"
        end
      end

      def restart
        stop
        start
      end

      private

      def detect_forking
        if @pid != $$
          logger.info "name=flipper_telemetry action=fork_detected pid_was#{@pid} pid_is=#{$$}"
          restart
          @pid = $$
        end
      end

      def post_to_pool
        logger.debug "name=flipper_telemetry action=post_to_pool"
        drained = @metric_storage.drain
        return if drained.empty?
        @pool.post { post_to_cloud(drained) }
      end

      def post_to_cloud(drained)
        response, error = @cloud_configuration.telemetry_submitter.call(drained)
        # Some of the errors are response code errors which have a response and
        # thus may have a telemetry-interval header for us to respect.
        response ||= error.response if error.respond_to?(:response)
        if response && telemetry_interval = response["telemetry-interval"]
          telemetry_interval = telemetry_interval.to_i
          @timer.execution_interval = telemetry_interval
          @cloud_configuration.telemetry_interval = telemetry_interval
        end
      rescue => error
        logger.debug "name=flipper_telemetry action=post_to_cloud error=#{error.inspect}"
      end
    end
  end
end