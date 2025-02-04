require "concurrent/map"
require "concurrent/timer_task"
require "concurrent/executor/fixed_thread_pool"
require "flipper/typecast"
require "flipper/cloud/telemetry/metric"
require "flipper/cloud/telemetry/metric_storage"
require "flipper/cloud/telemetry/submitter"

module Flipper
  module Cloud
    class Telemetry
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

      # Public: The cloud configuration to use for this telemetry instance.
      attr_reader :cloud_configuration

      # Internal: Where the metrics are stored between cloud submissions.
      attr_reader :metric_storage

      # Internal: The pool of background threads that submits metrics to cloud.
      attr_reader :pool

      # Internal: The timer that triggers draining the metrics to the pool.
      attr_reader :timer

      # Internal: The interval in seconds for how often telemetry should be sent to cloud.
      attr_reader :interval

      # Internal: The timeout in seconds for how long to wait for the pool to shutdown.
      attr_reader :shutdown_timeout

      # Internal: The proc that is called to submit metrics to cloud.
      attr_accessor :submitter

      def initialize(cloud_configuration)
        @pid = $$
        @cloud_configuration = cloud_configuration
        self.interval = ENV.fetch("FLIPPER_TELEMETRY_INTERVAL", 60).to_f
        self.shutdown_timeout = ENV.fetch("FLIPPER_TELEMETRY_SHUTDOWN_TIMEOUT", 5).to_f
        self.submitter = ->(drained) { Submitter.new(@cloud_configuration).call(drained) }
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

      # Public: Start all the tasks and setup new metric storage.
      def start
        info "action=start"

        @metric_storage = MetricStorage.new

        @pool = Concurrent::FixedThreadPool.new(1, {
          max_queue: 20, # ~ 20 minutes of data at 1 minute intervals
          fallback_policy: :discard,
          name: "flipper-telemetry-post-to-cloud-pool".freeze,
        })

        @timer = Concurrent::TimerTask.execute({
          execution_interval: interval,
          name: "flipper-telemetry-post-to-pool-timer".freeze,
        }) { post_to_pool }
      end

      # Public: Shuts down all the tasks and tries to flush any remaining info to Cloud.
      def stop
        info "action=stop"

        if @timer
          debug "action=timer_shutdown_start"
          @timer.shutdown
          # no need to wait long for timer, all it does is drain in memory metric
          # storage and post to the pool of background workers
          timer_termination_result = @timer.wait_for_termination(1)
          @timer.kill unless timer_termination_result
          debug "action=timer_shutdown_end result=#{timer_termination_result}"
        end

        if @pool
          post_to_pool # one last drain
          debug "action=pool_shutdown_start"
          @pool.shutdown
          pool_termination_result = @pool.wait_for_termination(@shutdown_timeout)
          @pool.kill unless pool_termination_result
          debug "action=pool_shutdown_end result=#{pool_termination_result}"
        end
      end

      # Public: Restart all the tasks and reset the storage.
      def restart
        stop
        start
      end

      # Internal: Sets the interval in seconds for how often telemetry should be sent to cloud.
      def interval=(value)
        new_interval = [Typecast.to_float(value), 10].max
        @timer&.execution_interval = new_interval
        @interval = new_interval
      end

      # Internal: Sets the timeout in seconds for how long to wait for the pool to shutdown.
      def shutdown_timeout=(value)
        new_shutdown_timeout = [Typecast.to_float(value), 0.1].max
        @shutdown_timeout = new_shutdown_timeout
      end

      private

      def detect_forking
        if @pid != $$
          info "action=fork_detected pid_was#{@pid} pid_is=#{$$}"
          restart
          @pid = $$
        end
      end

      # Drains the metric storage and enqueues the metrics to be posted to cloud.
      def post_to_pool
        drained = @metric_storage.drain
        return if drained.empty?
        debug "action=post_to_pool metrics=#{drained.size}"
        @pool.post { post_to_cloud(drained) }
      rescue => error
        error "action=post_to_pool error=#{error.inspect}"
      end

      # Posts the drained metrics to cloud.
      def post_to_cloud(drained)
        debug "action=post_to_cloud metrics=#{drained.size}"
        response, error = submitter.call(drained)
        debug "action=post_to_cloud response=#{response.inspect} body=#{response&.body.inspect} error=#{error.inspect}"

        # Some of the errors are response code errors which have a response and
        # thus may have a telemetry-interval header for us to respect.
        response ||= error.response if error && error.respond_to?(:response)

        if response
          if Flipper::Typecast.to_boolean(response["telemetry-shutdown"])
            debug "action=telemetry_shutdown message=The server has requested that telemetry be shut down."
            stop
            return
          end

          if interval = response["telemetry-interval"]
            self.interval = interval.to_f
          end
        end
      rescue => error
        error "action=post_to_cloud error=#{error.inspect}"
      end

      def error(message)
        @cloud_configuration.log message, level: :error
      end

      def info(message)
        @cloud_configuration.log message, level: :info
      end

      def debug(message)
        @cloud_configuration.log message
      end
    end
  end
end
