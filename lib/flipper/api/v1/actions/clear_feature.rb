require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class ClearFeature < Api::Action
          route %r{features/[^/]*/clear/?\Z}

          def delete
            feature_name = Rack::Utils.unescape(path_parts[-2])
            feature = flipper[feature_name]
            flipper.adapter.clear(feature)
            json_response({}, 204)
          end
        end
      end
    end
  end
end
