require "flipper/export"

module Flipper
  module Exporters
    module Json
      # Internal: JSON export class that knows how to build features hash
      # from input.
      class Export < ::Flipper::Export
        def initialize(input:, version: 1)
          super input: input, version: version, format: :json
        end

        # Public: The features hash identical to calling get_all on adapter.
        def features
          @features ||= begin
            features = JSON.parse(input).fetch("features")

            result = {}
            features.each do |feature_key, gates|
              result[feature_key] = {}
              gates.each do |gate_key, value|
                result[feature_key][gate_key.to_sym] = value
              end
            end

            result
          end
        end
      end
    end
  end
end
