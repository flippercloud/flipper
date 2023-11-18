require "forwardable"
require "securerandom"
require "concurrent/timer_task"
require "concurrent/executor/fixed_thread_pool"
require "flipper/cloud/telemetry/metric"
require "flipper/cloud/telemetry/metric_storage"
require "flipper/serializers/json"
require "flipper/serializers/gzip"

module Flipper
  module Cloud
    class Telemetry
      extend Forwardable

      SCHEMA_VERSION = "V1".freeze

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

      attr_reader :cloud_configuration, :metric_storage

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
        @pool = Concurrent::FixedThreadPool.new(5, pool_options)
        @timer = Concurrent::TimerTask.execute(timer_options) { post_to_pool }
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
        return if drained.empty?
        logger.debug "name=flipper_telemetry action=post_to_cloud"

        enabled_metrics = drained.map { |metric, value|
          metric.as_json(with: {"value" => value})
        }

        body = Typecast.to_json({
          request_id: SecureRandom.uuid,
          enabled_metrics: enabled_metrics,
        })
        http_client = @cloud_configuration.http_client
        http_client.add_header :schema_version, SCHEMA_VERSION
        http_client.add_header :content_encoding, 'gzip'
        http_client.post "/telemetry", Typecast.to_gzip(body)
      rescue => error
        # FIXME: Retry for net/http server errors
        logger.debug "name=flipper_telemetry action=post_to_cloud error=#{error.inspect}"
      end

      def pool_options
        {
          max_queue: 5,
          fallback_policy: :discard,
          name: "flipper-telemetry-post-to-cloud-pool".freeze,
        }
      end

      def timer_options
        {
          execution_interval: @cloud_configuration.telemetry_interval,
          name: "flipper-telemetry-post-to-pool-timer".freeze,
        }
      end
    end
  end
end
