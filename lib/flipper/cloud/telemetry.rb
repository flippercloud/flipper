require "json"
require "concurrent/timer_task"
require "concurrent/executor/fixed_thread_pool"
require "flipper/cloud/telemetry/metric"
require "flipper/cloud/telemetry/metric_storage"

module Flipper
  module Cloud
    class Telemetry
      SCHEMA_VERSION = "V1".freeze

      attr_reader :cloud_configuration, :metric_storage

      def self.instances
        @instances ||= Concurrent::Map.new
      end
      private_class_method :instances

      # Internal: Fetch an instance of telemetry once per process per url +
      # token (aka cloud endpoint). Should only ever be one instance unless you
      # are doing some funky stuff.
      def self.instance_for(cloud_configuration)
        instances.compute_if_absent(cloud_configuration.url + cloud_configuration.token) do
          new(cloud_configuration)
        end
      end

      def initialize(cloud_configuration)
        @pid = $$
        @logger = Logger.new(STDOUT)
        @cloud_configuration = cloud_configuration
        start

        at_exit { stop }
      end

      # Records enabled metrics based on feature key and resulting value.
      def record_enabled(feature_key, result)
        detect_forking
        @metric_storage&.increment Metric.new(feature_key, result)
      end

      def start
        @logger.info "pid=#{@pid} name=flipper_telemetry action=start"
        @metric_storage = MetricStorage.new
        @pool = Concurrent::FixedThreadPool.new(5, pool_options)
        @timer = Concurrent::TimerTask.execute(timer_options) { post_to_pool }
      end

      # Shuts down all the tasks and tries to flush any remaining info to Cloud.
      def stop
        @logger.info "pid=#{@pid} name=flipper_telemetry action=stop"

        if @timer
          @logger.info "pid=#{@pid} name=flipper_telemetry action=timer_shutdown_start"
          @timer.shutdown
          # no need to wait long for timer, all it does is drain in memory metric
          # storage and post to the pool of background workers
          timer_termination_result = @timer.wait_for_termination(1)
          @timer.kill unless timer_termination_result
          @logger.info "pid=#{@pid} name=flipper_telemetry action=timer_shutdown_end result=#{timer_termination_result}"
        end

        if @pool
          post_to_pool # one last drain
          @logger.info "pid=#{@pid} name=flipper_telemetry action=pool_shutdown_start"
          @pool.shutdown
          pool_termination_result = @pool.wait_for_termination(@cloud_configuration.telemetry_shutdown_timeout)
          @pool.kill unless pool_termination_result
          @logger.info "pid=#{@pid} name=flipper_telemetry action=pool_shutdown_end result=#{pool_termination_result}"
        end
      end

      def restart
        stop
        start
      end

      private

      def detect_forking
        if @pid != $$
          @logger.info "pid=#{@pid} name=flipper_telemetry action=fork_detected pid_was#{@pid} pid_is=#{$$}"
          restart
          @pid = $$
        end
      end

      def post_to_pool
        @logger.info "pid=#{@pid} name=flipper_telemetry action=post_to_pool"
        drained = @metric_storage.drain
        return if drained.empty?
        @pool.post { post_to_cloud(drained) }
      end

      def post_to_cloud(drained)
        return if drained.empty?
        @logger.info "pid=#{@pid} name=flipper_telemetry action=post_to_cloud"

        enabled_metrics = drained.inject([]) do |array, (metric, value)|
          array << {
            key: metric.key,
            time: metric.time,
            result: metric.result,
            value: value,
          }
          array
        end

        body = JSON.generate({
          enabled_metrics: enabled_metrics,
        })
        http_client = @cloud_configuration.http_client
        http_client.add_header :schema_version, SCHEMA_VERSION
        http_client.post "/telemetry", body
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
