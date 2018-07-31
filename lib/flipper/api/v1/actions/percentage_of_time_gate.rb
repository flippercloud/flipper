require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class PercentageOfTimeGate < Api::Action
          REGEX = %r{\A/features/(?<feature_name>.*)/percentage_of_time/?\Z}
          route REGEX

          def post
            if percentage < 0 || percentage > 100
              json_error_response(:percentage_invalid)
            end

            feature = flipper[feature_name]
            feature.enable_percentage_of_time(percentage)
            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          def delete
            feature = flipper[feature_name]
            feature.disable_percentage_of_time

            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          private

          def feature_name
            @feature_name ||= begin
              match = request.path_info.match(REGEX)
              match ? match[:feature_name] : nil
            end
          end

          def percentage
            @percentage ||= begin
              Integer(params['percentage'])
            rescue ArgumentError, TypeError
              -1
            end
          end
        end
      end
    end
  end
end
