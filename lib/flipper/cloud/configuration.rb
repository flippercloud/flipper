require "logger"
require "socket"
require "flipper/adapters/http"
require "flipper/adapters/poll"
require "flipper/poller"
require "flipper/adapters/dual_write"
require "flipper/adapters/sync/synchronizer"
require "flipper/cloud/telemetry"
require "flipper/cloud/telemetry/instrumenter"
require "flipper/cloud/telemetry/submitter"

module Flipper
  module Cloud
    class Configuration
      # The set of valid ways that syncing can happpen.
      VALID_SYNC_METHODS = Set[
        :poll,
        :webhook,
      ].freeze

      DEFAULT_URL = "https://www.flippercloud.io/adapter".freeze

      # Public: The token corresponding to an environment on flippercloud.io.
      attr_accessor :token

      # Public: The url for http adapter. Really should only be customized for
      #         development work if you are me and you are not me. Feel free to
      #         forget you ever saw this.
      attr_accessor :url

      # Public: net/http read timeout for all http requests (default: 5).
      attr_accessor :read_timeout

      # Public: net/http open timeout for all http requests (default: 5).
      attr_accessor :open_timeout

      # Public: net/http write timeout for all http requests (default: 5).
      attr_accessor :write_timeout

      # Public: IO stream to send debug output too. Off by default.
      #
      #  # for example, this would send all http request information to STDOUT
      #  configuration = Flipper::Cloud::Configuration.new
      #  configuration.debug_output = STDOUT
      attr_accessor :debug_output

      # Public: Instrumenter to use for the Flipper instance returned by
      #         Flipper::Cloud.new (default: Flipper::Instrumenters::Noop).
      #
      #  # for example, to use active support notifications you could do:
      #  configuration = Flipper::Cloud::Configuration.new
      #  configuration.instrumenter = ActiveSupport::Notifications
      attr_accessor :instrumenter

      # Public: Local adapter that all reads should go to in order to ensure
      # latency is low and resiliency is high. This adapter is automatically
      # kept in sync with cloud.
      #
      #  # for example, to use active record you could do:
      #  configuration = Flipper::Cloud::Configuration.new
      #  configuration.local_adapter = Flipper::Adapters::ActiveRecord.new
      attr_accessor :local_adapter

      # Public: The Integer or Float number of seconds between attempts to bring
      # the local in sync with cloud (default: 10).
      attr_accessor :sync_interval

      # Public: The secret used to verify if syncs in the middleware should
      # occur or not.
      attr_accessor :sync_secret

      # Public: The logger to use for debugging inner workings.
      attr_accessor :logger

      # Public: Should the logger log or not (default: true).
      attr_accessor :logging_enabled

      # Public: The telemetry instance to use for tracking feature usage.
      attr_accessor :telemetry

      # Public: Should telemetry be enabled or not (default: false).
      attr_accessor :telemetry_enabled

      def initialize(options = {})
        setup_auth options
        setup_log options
        setup_http options
        setup_sync options
        setup_adapter options
        setup_telemetry options
      end

      # Public: Read or customize the http adapter. Calling without a block will
      # perform a read. Calling with a block yields the cloud adapter
      # for customization.
      #
      #   # for example, to instrument the http calls, you can wrap the http
      #   # adapter with the intsrumented adapter
      #   configuration = Flipper::Cloud::Configuration.new
      #   configuration.adapter do |adapter|
      #     Flipper::Adapters::Instrumented.new(adapter)
      #   end
      #
      def adapter(&block)
        if block_given?
          @adapter_block = block
        else
          @adapter_block.call app_adapter
        end
      end

      # Public: Force a sync.
      def sync
        Flipper::Adapters::Sync::Synchronizer.new(local_adapter, http_adapter, {
          instrumenter: instrumenter,
        }).call
      end

      # Public: The method that will be used to synchronize local adapter with
      # cloud. (default: :poll, will be :webhook if sync_secret is set).
      def sync_method
        sync_secret ? :webhook : :poll
      end

      # Internal: The http client used by the http adapter. Exposed so we can
      # use the same client for posting telemetry.
      def http_client
        http_adapter.client
      end

      # Internal: Logs message if logging is enabled.
      def log(message, level: :debug)
        return unless logging_enabled
        logger.send(level, "name=flipper_cloud #{message}")
      end

      def instrument(name, payload = {}, &block)
        instrumenter.instrument(name, payload, &block)
      end

      private

      def app_adapter
        read_adapter = sync_method == :webhook ? local_adapter : poll_adapter
        Flipper::Adapters::DualWrite.new(read_adapter, http_adapter)
      end

      def poller
        Flipper::Poller.get(@url + @token, {
          interval: sync_interval,
          remote_adapter: http_adapter,
          instrumenter: instrumenter,
        }).tap(&:start)
      end

      def poll_adapter
        Flipper::Adapters::Poll.new(poller, local_adapter)
      end

      def http_adapter
        Flipper::Adapters::Http.new({
          url: @url,
          read_timeout: @read_timeout,
          open_timeout: @open_timeout,
          write_timeout: @write_timeout,
          max_retries: 0, # we'll handle retries ourselves
          debug_output: @debug_output,
          headers: {
            "flipper-cloud-token" => @token,
            "accept-encoding" => "gzip",
          },
        })
      end

      def setup_auth(options)
        set_option :token, options, required: true
      end

      def setup_log(options)
        set_option :logging_enabled, options, default: false, typecast: :boolean
        set_option :logger, options, from_env: false, default: -> {
          if logging_enabled
            Logger.new(STDOUT)
          else
            Logger.new("/dev/null")
          end
        }
      end

      def setup_http(options)
        set_option :url, options, default: DEFAULT_URL
        set_option :debug_output, options, from_env: false

        if @debug_output.nil? && Flipper::Typecast.to_boolean(ENV["FLIPPER_CLOUD_DEBUG_OUTPUT_STDOUT"])
          @debug_output = STDOUT
        end

        set_option :read_timeout, options, default: 5, typecast: :float, minimum: 0.1
        set_option :open_timeout, options, default: 2, typecast: :float, minimum: 0.1
        set_option :write_timeout, options, default: 5, typecast: :float, minimum: 0.1
      end

      def setup_sync(options)
        set_option :sync_interval, options, default: 10, typecast: :float, minimum: 10
        set_option :sync_secret, options
      end

      def setup_adapter(options)
        set_option :local_adapter, options, default: -> { Adapters::Memory.new }, from_env: false
        @adapter_block = ->(adapter) { adapter }
      end

      def setup_telemetry(options)
        # Needs to be after url and token assignments because they are used for
        # uniqueness in Telemetry.instance_for.
        set_option :telemetry, options, from_env: false, default: -> {
          Telemetry.instance_for(self)
        }

        set_option :telemetry_enabled, options, default: true, typecast: :boolean
        instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
        @instrumenter = if telemetry_enabled
          Telemetry::Instrumenter.new(self, instrumenter)
        else
          instrumenter
        end
      end

      # Internal: Super helper for defining an option that can be set via
      # options hash or ENV with defaults, typecasting and minimums.
      def set_option(name, options, default: nil, typecast: nil, minimum: nil, from_env: true, required: false)
        env_var = "FLIPPER_CLOUD_#{name.to_s.upcase}"
        value = options.fetch(name) {
          default_value = default.respond_to?(:call) ? default.call : default
          if from_env
            ENV.fetch(env_var, default_value)
          else
            default_value
          end
        }
        value = Flipper::Typecast.send("to_#{typecast}", value) if typecast
        send("#{name}=", value)
        enforce_minimum(name, minimum) if minimum

        if required
          option_value = send(name)
          if option_value.nil? || option_value.empty?
            message = String.new("Flipper::Cloud #{name} is missing. Please ")
            message << "set #{env_var} or " if from_env
            message << "provide #{name} (e.g. Flipper::Cloud.new(#{name}: value))."
            raise ArgumentError, message
          end
        end
      end

      # Enforce minimum interval for tasks that run on a timer.
      def enforce_minimum(name, minimum)
        provided = send(name)
        if provided && provided < minimum
          warn "Flipper::Cloud##{name} must be at least #{minimum} seconds but was #{provided}. Using #{minimum} seconds."
          send(:instance_variable_set, "@#{name}", minimum)
        end
      end
    end
  end
end
