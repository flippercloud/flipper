require 'flipper/api/action'

module Flipper
  module Api
    module V1
      module Actions
        class BooleanGate < Api::Action
          route %r{api/v1/features/[^/]*/(enable|disable)/?\Z}
          
          def put
            feature_name = Rack::Utils.unescape(path_parts[-2])
            feature = flipper[feature_name.to_sym]
            action = Rack::Utils.unescape(path_parts.last)
            feature.send(action)
            json_response({}, 204)
          end
        end
      end
    end
  end
end
