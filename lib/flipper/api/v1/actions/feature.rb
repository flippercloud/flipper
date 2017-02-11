require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class Feature < Api::Action
          route %r{api/v1/features/[^/]*/?\Z}

          def get
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
        end
      end
    end
  end
end
