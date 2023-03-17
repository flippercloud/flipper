require "json"

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

          JSON.dump({
            version: VERSION,
            features: features,
          })
        end
      end
    end
  end
end
