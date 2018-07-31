require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class ClearFeature < Api::Action
          REGEX = %r{\A/features/(?<feature_name>.*)/clear/?\Z}
          route REGEX

          def delete
            feature = flipper[feature_name]
            feature.clear
            json_response({}, 204)
          end

          private

          def feature_name
            @feature_name ||= begin
              match = request.path_info.match(REGEX)
              match ? match[:feature_name] : nil
            end
          end
        end
      end
    end
  end
end
