require "json"
require "flipper/exporters/json/export"

module Flipper
  module Exporters
    module Json
      class V1
        VERSION = 1

        def call(adapter)
          features = adapter.get_all

          # Convert sets to arrays for json
          features.each do |feature_key, gates|
            gates.each do |key, value|
              case value
              when Set
                features[feature_key][key] = value.to_a
              end
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
