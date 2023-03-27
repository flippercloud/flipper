require "flipper/exporters/json/v1"

module Flipper
  module Exporter
    extend self

    FORMATTERS = {
      json: {
        1 => Flipper::Exporters::Json::V1,
      }
    }.freeze

    def build(format: :json, version: 1)
      FORMATTERS.fetch(format).fetch(version).new
    end
  end
end
