require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class Feature < Api::Action

          route %r{api/v1/features/[^/]*/?\Z}

          def get
            if feature_names.include?(feature_name)
              feature = Decorators::Feature.new(flipper[feature_name])
              json_response(feature.as_json)
            else
              json_response({}, 404)
            end
          end

          def delete
            feature = flipper[feature_name]
            flipper.adapter.remove(feature)
            json_response({}, 204)
          end

          private
          
          def feature_name
            @feature_name ||= Rack::Utils.unescape(path_parts.last)
          end

          def feature_names
            @feature_names ||= flipper.adapter.features
          end
        end
      end
    end
  end
end
