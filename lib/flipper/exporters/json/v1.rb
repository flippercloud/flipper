require "json"
require "flipper/export"

module Flipper
  module Exporters
    module Json
      class V1
        VERSION = 1

        def call(adapter)
          features = adapter.get_all

          features.each do |feature_key, gates|
            gates.each do |key, value|
              case value
              when Set
                features[feature_key][key] = value.to_a
              end
            end
          end

          json = JSON.dump({
            version: VERSION,
            features: features,
          })

          Export.new(input: json, format: :json, version: VERSION)
        end
      end
    end
  end
end
