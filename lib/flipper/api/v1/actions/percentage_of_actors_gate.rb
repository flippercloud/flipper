require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class PercentageOfActorsGate < Api::Action
          include FeatureNameFromRoute

          route %r{\A/features/(?<feature_name>.*)/percentage_of_actors/?\Z}

          def post
            if percentage < 0 || percentage > 100
              json_error_response(:percentage_invalid)
            end

            feature = flipper[feature_name]
            feature.enable_percentage_of_actors(percentage)
            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          def delete
            feature = flipper[feature_name]
            feature.disable_percentage_of_actors
            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          private

          def percentage_param
            @percentage_param ||= params['percentage'].to_s
          end

          def percentage
            @percentage ||= begin
              unless percentage_param.match(/\d/)
                raise ArgumentError, "invalid numeric value: #{percentage_param}"
              end

              Flipper::Types::Percentage.new(percentage_param).value
            rescue ArgumentError, TypeError
              -1
            end
          end
        end
      end
    end
  end
end
