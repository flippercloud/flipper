require 'flipper/api/action'

module Flipper
  module Api
    module V1
      module Actions
        class BooleanGate < Api::Action
          route %r{api/v1/features/[^/]*/boolean/?\Z}

          def post
            feature_name = Rack::Utils.unescape(path_parts[-2])
            feature = flipper[feature_name.to_sym]
            feature.enable
            json_response({}, 204)
          end

          def delete
            feature_name = Rack::Utils.unescape(path_parts[-2])
            feature = flipper[feature_name.to_sym]
            feature.disable
            json_response({}, 204)
          end
        end
      end
    end
  end
end
