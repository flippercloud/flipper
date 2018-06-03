require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class BooleanGate < Api::Action
          REGEX = %r{\A/features/(.*)/boolean/?\Z}
          match { |request| request.path_info =~ REGEX }

          def post
            feature = flipper[feature_name]
            feature.enable
            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          def delete
            feature = flipper[feature_name.to_sym]
            feature.disable
            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          private

          def feature_name
            @feature_name ||= begin
              match = request.path_info.match(REGEX)
              match ? match[1] : nil
            end
          end
        end
      end
    end
  end
end
