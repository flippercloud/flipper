require "socket"
require "flipper/adapters/http"
require "flipper/adapters/memory"
require "flipper/adapters/dual_write"
require "flipper/adapters/sync"
require "flipper/cloud/instrumenter"
require "flipper/cloud/registry"
require "brow"

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

      def initialize(options = {})
        @token = options.fetch(:token) { ENV["FLIPPER_CLOUD_TOKEN"] }

        if @token.nil?
          raise ArgumentError, "Flipper::Cloud token is missing. Please set FLIPPER_CLOUD_TOKEN or provide the token (e.g. Flipper::Cloud.new(token: 'token'))."
        end

        if ENV["FLIPPER_CLOUD_SYNC_METHOD"]
          warn "FLIPPER_CLOUD_SYNC_METHOD is deprecated and has no effect."
        end
        self.sync_method = options[:sync_method] if options[:sync_method]

        @read_timeout = options.fetch(:read_timeout) { ENV.fetch("FLIPPER_CLOUD_READ_TIMEOUT", 5).to_f }
        @open_timeout = options.fetch(:open_timeout) { ENV.fetch("FLIPPER_CLOUD_OPEN_TIMEOUT", 5).to_f }
        @write_timeout = options.fetch(:write_timeout) { ENV.fetch("FLIPPER_CLOUD_WRITE_TIMEOUT", 5).to_f }
        @sync_interval = options.fetch(:sync_interval) { ENV.fetch("FLIPPER_CLOUD_SYNC_INTERVAL", 10).to_f }
        @sync_secret = options.fetch(:sync_secret) { ENV["FLIPPER_CLOUD_SYNC_SECRET"] }
        @local_adapter = options.fetch(:local_adapter) { Adapters::Memory.new }
        @debug_output = options[:debug_output]
        @adapter_block = ->(adapter) { adapter }
        self.url = options.fetch(:url) { ENV.fetch("FLIPPER_CLOUD_URL", DEFAULT_URL) }

        instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)

        # This is alpha. Don't use this unless you are me. And you are not me.
        cloud_instrument = options.fetch(:cloud_instrument) { ENV["FLIPPER_CLOUD_INSTRUMENT"] == "1" }
        @instrumenter = if cloud_instrument
          Instrumenter.new(brow: brow, instrumenter: instrumenter)
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

      # Public: Set url for the http adapter.
      attr_writer :url

      def sync
        Flipper::Adapters::Sync::Synchronizer.new(local_adapter, http_adapter, {
          instrumenter: instrumenter,
          interval: sync_interval,
        }).call
      end

      def brow
        uri = URI.parse(url)
        uri.path = "#{uri.path}/events".squeeze("/")
        events_url = uri.to_s

        Registry.default.fetch(events_url) {
          Brow::Client.new({
            url: events_url,
            headers: {
              "Accept" => "application/json",
              "Content-Type" => "application/json",
              "User-Agent" => "Flipper v#{VERSION} via Brow v#{Brow::VERSION}",
              "Flipper-Cloud-Token" => @token,
            }
          })
        }
      end

      # Public: The method that will be used to synchronize local adapter with
      # cloud. (default: :poll, will be :webhook if sync_secret is set).
      def sync_method
        sync_secret ? :webhook : :poll
      end

      def sync_method=(_)
        warn "Flipper::Cloud: sync_method is deprecated and has no effect."
      end

      private

      def app_adapter
        sync_method == :webhook ? dual_write_adapter : sync_adapter
      end

      def dual_write_adapter
        Flipper::Adapters::DualWrite.new(local_adapter, http_adapter)
      end

      def sync_adapter
        Flipper::Adapters::Sync.new(local_adapter, http_adapter, {
          instrumenter: instrumenter,
          interval: sync_interval,
        })
      end

      def http_adapter
        Flipper::Adapters::Http.new({
          url: @url,
          read_timeout: @read_timeout,
          open_timeout: @open_timeout,
          debug_output: @debug_output,
          headers: {
            "Flipper-Cloud-Token" => @token,
          },
        })
      end
    end
  end
end
