require "flipper/adapters/http"
require "flipper/instrumenters/noop"

module Flipper
  module Cloud
    def self.new(token, options = {})
      url = options.fetch(:url, "https://www.featureflipper.com/adapter")
      instrumenter = options.fetch(:instrumenter, Flipper::Instrumenters::Noop)

      http_options = {
        uri: URI(url),
        headers: {
          "Feature-Flipper-Token" => token,
        },
      }
      adapter = Flipper::Adapters::Http.new(http_options)
      Flipper.new(adapter, instrumenter: instrumenter)
    end
  end
end
