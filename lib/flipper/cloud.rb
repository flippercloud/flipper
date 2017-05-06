require "flipper/adapters/http"
require "flipper/instrumenters/noop"

module Flipper
  module Cloud
    def self.new(token, options = {})
      url = options.fetch(:url) { "https://www.featureflipper.com/adapter" }
      instrumenter = options.fetch(:instrumenter, Flipper::Instrumenters::Noop)
      adapter = Flipper::Adapters::Http.new(uri: URI(url),
                                            headers: {
                                              "Feature-Flipper-Token" => token,
                                            })
      Flipper.new(adapter, instrumenter: instrumenter)
    end
  end
end
