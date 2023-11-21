require "logger"
require "socket"
require "flipper/adapters/http"
require "flipper/adapters/poll"
require "flipper/poller"
require "flipper/adapters/memory"
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
       #        development work. Feel free to forget you ever saw this.
      attr_reader :url

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

      # Public: Set the url for http adapter. Really should only be customized
      # by me and you are not me.
      attr_accessor :url

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

      # Public: The telemetry instance to use for tracking feature usage.
      attr_accessor :telemetry

      # Public: The telemetry submitter to use for sending telemetry to Cloud.
      attr_accessor :telemetry_submitter

      # Public: The telemetry logger to use for debugging telemetry inner workings.
      attr_accessor :telemetry_logger

      # Public: The Integer for Float number of seconds between submission of
      # telemetry to Cloud (default: 60, minimum: 10).
      attr_accessor :telemetry_interval

      # Public: The Integer or Float number of seconds to wait for telemetry
      # to shutdown (default: 5).
      attr_accessor :telemetry_shutdown_timeout

      def initialize(options = {})
        @token = options.fetch(:token) { ENV["FLIPPER_CLOUD_TOKEN"] }

        if @token.nil?
          raise ArgumentError, "Flipper::Cloud token is missing. Please set FLIPPER_CLOUD_TOKEN or provide the token (e.g. Flipper::Cloud.new(token: 'token'))."
        end

        # Http related setup.
        @url = options.fetch(:url) { ENV.fetch("FLIPPER_CLOUD_URL", DEFAULT_URL) }
        @debug_output = options[:debug_output]
        @read_timeout = options.fetch(:read_timeout) {
          ENV.fetch("FLIPPER_CLOUD_READ_TIMEOUT", 5).to_f
        }
        @open_timeout = options.fetch(:open_timeout) {
          ENV.fetch("FLIPPER_CLOUD_OPEN_TIMEOUT", 5).to_f
        }
        @write_timeout = options.fetch(:write_timeout) {
          ENV.fetch("FLIPPER_CLOUD_WRITE_TIMEOUT", 5).to_f
        }
        enforce_minimum(:read_timeout, 0.1)
        enforce_minimum(:open_timeout, 0.1)
        enforce_minimum(:write_timeout, 0.1)

        # Sync setup.
        @sync_interval = options.fetch(:sync_interval) {
          ENV.fetch("FLIPPER_CLOUD_SYNC_INTERVAL", 10).to_f
        }
        @sync_secret = options.fetch(:sync_secret) {
          ENV["FLIPPER_CLOUD_SYNC_SECRET"]
        }
        enforce_minimum(:sync_interval, 10)

        # Adapter setup.
        @local_adapter = options.fetch(:local_adapter) { Adapters::Memory.new }
        @adapter_block = ->(adapter) { adapter }

        # Telemetry setup.
        @telemetry_logger = options.fetch(:telemetry_logger) {
          if Flipper::Typecast.to_boolean(ENV["FLIPPER_CLOUD_TELEMETRY_LOGGING"])
            Logger.new(STDOUT)
          else
            Logger.new("/dev/null")
          end
        }
        @telemetry_interval = options.fetch(:telemetry_interval) {
          ENV.fetch("FLIPPER_CLOUD_TELEMETRY_INTERVAL", 60).to_f
        }
        @telemetry_shutdown_timeout = options.fetch(:telemetry_shutdown_timeout) {
          ENV.fetch("FLIPPER_CLOUD_TELEMETRY_SHUTDOWN_TIMEOUT", 5).to_f
        }
        @telemetry_submitter = options.fetch(:telemetry_submitter) {
          ->(drained) { Telemetry::Submitter.new(self).call(drained) }
        }
        # Needs to be after url and other telemetry config assignments.
        @telemetry = options.fetch(:telemetry) { Telemetry.instance_for(self) }
        enforce_minimum(:telemetry_interval, 10)
        enforce_minimum(:telemetry_shutdown_timeout, 0)

        # This is alpha. Don't use this unless you are me. And you are not me.
        instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
        cloud_instrument = options.fetch(:cloud_instrument) {
          Flipper::Typecast.to_boolean(ENV["FLIPPER_CLOUD_INSTRUMENT"])
        }
        @instrumenter = if cloud_instrument
          Telemetry::Instrumenter.new(self, instrumenter)
        else
          instrumenter
        end
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
            "Flipper-Cloud-Token" => @token,
          },
        })
      end

      # Enforce minimum interval for tasks that run on a timer.
      def enforce_minimum(name, minimum)
        provided = send(name)
        if provided < minimum
          warn "Flipper::Cloud##{name} must be at least #{minimum} seconds but was #{provided}. Using #{minimum} seconds."
          send("#{name}=", minimum)
        end
      end
    end
  end
end
