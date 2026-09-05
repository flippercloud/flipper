require "json"
require "flipper/exporters/json/export"

module Flipper
  module Exporters
    module Json
      class V1
        VERSION = 1

        def call(adapter)
          # Build a new structure rather than mutating the hash returned by
          # the adapter, which may be a reference to the adapter's live data.
          features = adapter.get_all.transform_values do |gates|
            gates.transform_values do |value|
              value.is_a?(Set) ? value.to_a : value
            end
          end

          json = Typecast.to_json({
            version: VERSION,
            features: features,
          })

          Json::Export.new(contents: json, version: VERSION)
        end
      end
    end
  end
end
