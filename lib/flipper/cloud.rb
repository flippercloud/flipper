require "flipper/adapters/http"

module Flipper
  module Cloud
    def self.new(token, options = {})
      url = options.fetch(:url) { "https://www.featureflipper.com/adapter" }
      adapter = Flipper::Adapters::Http.new({
        uri: URI(url),
        headers: {
          "Feature-Flipper-Token" => token,
        },
      })
      Flipper.new(adapter)
    end
  end
end
