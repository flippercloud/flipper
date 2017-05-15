require "flipper/adapters/http"
require "flipper/instrumenters/noop"

module Flipper
  module Cloud
    # The default adapter wrapper which doesn't wrap at all.
    DEFAULT_ADAPTER_WRAPPER_BLOCK = ->(adapter) { adapter }

    # The default url should be the one, the only, the website.
    DEFAULT_URL = "https://www.featureflipper.com/adapter".freeze

    # Public: Returns a new Flipper instance with an http adapter correctly
    # configured for flipper cloud.
    #
    # token - The String token for the environment from the website.
    # options - The Hash of options.
    #           # :url - The url to point at (defaults to DEFAULT_URL).
    #           # :adapter_wrapper - The adapter wrapper block. Block should
    #                                receive an adapter and return an adapter.
    #                                Allows you to wrap the http adapter with
    #                                other adapters to make instrumentation and
    #                                caching easy.
    #           # :instrumenter - The optional instrumenter to use for the
    #                             Flipper::DSL instance (defaults to Noop).
    def self.new(token, options = {})
      url = options.fetch(:url, DEFAULT_URL)
      http_options = {
        uri: URI(url),
        headers: {
          "Feature-Flipper-Token" => token,
        },
        read_timeout: options[:read_timeout],
        open_timeout: options[:open_timeout],
        debug_output: options[:debug_output],
      }
      adapter = Flipper::Adapters::Http.new(http_options)

      adapter_wrapper = options.fetch(:adapter_wrapper, DEFAULT_ADAPTER_WRAPPER_BLOCK)
      adapter = adapter_wrapper.call(adapter)

      instrumenter = options.fetch(:instrumenter, Flipper::Instrumenters::Noop)
      Flipper.new(adapter, instrumenter: instrumenter)
    end
  end
end
