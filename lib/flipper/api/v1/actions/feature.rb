require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class Feature < Api::Action
          include FeatureNameFromRoute

          route %r{\A/features/(?<feature_name>.*)/?\Z}

          def get
            return json_error_response(:feature_not_found) unless feature_exists?(feature_name)
            exclude_gates = params['exclude_gates']&.downcase == "true"
            feature = Decorators::Feature.new(flipper[feature_name])
            json_response(feature.as_json(exclude_gates: exclude_gates))
          end

          def delete
            flipper.remove(feature_name)
            json_response({}, 204)
          end

          private

          def feature_exists?(feature_name)
            flipper.features.map(&:key).include?(feature_name)
          end
        end
      end
    end
  end
end
