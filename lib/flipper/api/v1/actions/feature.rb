require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class Feature < Api::Action
          route %r{features/[^/]*/?\Z}

          def get
            return json_error_response(:feature_not_found) unless feature_exists?(feature_name)
            feature = Decorators::Feature.new(flipper[feature_name])
            json_response(feature.as_json)
          end

          def delete
            flipper.remove(feature_name)
            json_response({}, 204)
          end

          private

          def feature_name
            @feature_name ||= Rack::Utils.unescape(path_parts.last)
          end

          def feature_exists?(feature_name)
            flipper.features.map(&:key).include?(feature_name)
          end
        end
      end
    end
  end
end
