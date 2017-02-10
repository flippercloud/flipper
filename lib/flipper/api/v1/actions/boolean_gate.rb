require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class BooleanGate < Api::Action
          route %r{features/[^/]*/boolean/?\Z}

          def post
            feature_name = Rack::Utils.unescape(path_parts[-2])
            feature = flipper[feature_name]
            feature.enable
            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          def delete
            feature_name = Rack::Utils.unescape(path_parts[-2])
            feature = flipper[feature_name.to_sym]
            feature.disable
            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end
        end
      end
    end
  end
end
