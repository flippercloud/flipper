require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class PercentageOfActorsGate < Api::Action
          route %r{features/[^/]*/percentage_of_actors/?\Z}

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

            if percentage >= 0
              feature.enable_percentage_of_actors(percentage)
            else
              feature.disable_percentage_of_actors
            end
            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          private

          def feature_name
            @feature_name ||= Rack::Utils.unescape(path_parts[-2])
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
