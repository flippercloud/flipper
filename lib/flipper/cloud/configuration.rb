require "flipper/adapters/http"
require "flipper/adapters/memory"
require "flipper/adapters/sync"

module Flipper
  module Cloud
    class Configuration
      # The default url should be the one, the only, the website.
      DEFAULT_URL = "https://www.flippercloud.io/adapter".freeze

      # The set of valid ways that syncing can happpen.
      VALID_SYNC_METHODS = Set[
        :poll,
        :webhook,
      ].freeze

      # Public: The token corresponding to an environment on flippercloud.io.
      attr_accessor :token

      # Public: The url for http adapter (default: Flipper::Cloud::DEFAULT_URL).
      #         Really should only be customized for development work. Feel free
      #         to forget you ever saw this.
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

      # Public: The method to be used for synchronizing your local flipper
      # adapter with cloud. (default: :poll, can also be :webhook).
      attr_accessor :sync_method

      def initialize(options = {})
        @token = options.fetch(:token)
        @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
        @read_timeout = options.fetch(:read_timeout, 5)
        @open_timeout = options.fetch(:open_timeout, 5)
        @write_timeout = options.fetch(:write_timeout, 5)
        @sync_interval = options.fetch(:sync_interval, 10)
        @sync_method = options.fetch(:sync_method, :poll)
        @local_adapter = options.fetch(:local_adapter) { Adapters::Memory.new }
        @debug_output = options[:debug_output]
        @adapter_block = ->(adapter) { adapter }

        self.url = options.fetch(:url, DEFAULT_URL)
        validate
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

      private

      def app_adapter
        sync_method == :webhook ? local_adapter : sync_adapter
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

      def validate
        unless VALID_SYNC_METHODS.include?(@sync_method)
          raise ArgumentError, "Unsupported sync_method. Valid options are (#{VALID_SYNC_METHODS.inspect})"
        end
      end
    end
  end
end
