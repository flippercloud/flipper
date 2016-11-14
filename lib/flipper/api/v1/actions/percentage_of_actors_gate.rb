require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class PercentageOfActorsGate < Api::Action
          route %r{api/v1/features/[^/]*/percentage_of_actors/?\Z}

          def post
            ensure_valid_enable_params
            feature = flipper[feature_name]
            feature.enable_percentage_of_actors(percentage)
            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          def delete
            ensure_valid_disable_params
            feature = flipper[feature_name]
            feature.disable_percentage_of_actors
            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          private

          def ensure_valid_enable_params
            unless feature_names.include?(feature_name)
              json_error_response(:feature_not_found)
            end

            if percentage < 0 || percentage > 100
              json_error_response(:percentage_invalid)
            end
          end

          def ensure_valid_disable_params
            unless feature_names.include?(feature_name)
              json_error_response(:feature_not_found)
            end
          end

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

            def feature_names
              @feature_names ||= flipper.adapter.features
            end
          end
        end
      end
    end
  end
