require "flipper/adapters/http"
require "flipper/instrumenters/noop"

module Flipper
  module Cloud
    class Configuration
      # The default url should be the one, the only, the website.
      DEFAULT_URL = "https://www.featureflipper.com/adapter".freeze

      # Public: The token corresponding to an environment on featureflipper.com.
      attr_accessor :token

      # Public: The url for http adapter (default: Flipper::Cloud::DEFAULT_URL).
      #         Really should only be customized for development work. Feel free
      #         to forget you ever saw this.
      attr_reader :url

      # Public: net/http read timeout for all http requests (default: 5).
      attr_accessor :read_timeout

      # Public: net/http open timeout for all http requests (default: 5).
      attr_accessor :open_timeout

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

      def initialize(options = {})
        @token = options.fetch(:token)
        @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
        @read_timeout = options.fetch(:read_timeout, 5)
        @open_timeout = options.fetch(:open_timeout, 5)
        @debug_output = options[:debug_output]
        @adapter_block = ->(adapter) { adapter }

        self.url = options.fetch(:url, DEFAULT_URL)
      end

      # Public: Read or customize the http adapter. Calling without a block will
      # perform a read. Calling with a block yields the http_adapter
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
          @adapter_block.call(http_adapter)
        end
      end

      # Public: Set url and uri for the http adapter.
      def url=(url)
        @url = url
      end

      private

      def http_adapter
        Flipper::Adapters::Http.new(url: @url,
                                    read_timeout: @read_timeout,
                                    open_timeout: @open_timeout,
                                    debug_output: @debug_output,
                                    headers: {
                                      "Feature-Flipper-Token" => @token,
                                    })
      end
    end
  end
end
