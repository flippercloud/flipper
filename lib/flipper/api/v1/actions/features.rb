require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'
require 'json'

module Flipper
  module Api
    module V1
      module Actions
        class Features < Api::Action

          route %r{api/v1/features\Z}

          def get
            features = flipper.features.map { |feature|
              Decorators::Feature.new(feature).as_json
            }

            json_response({
              features: features
            })
          end

          def post
            feature_name = params.fetch('name') { json_error_response(:name_invalid) }
            feature = flipper[feature_name]
            flipper.storage.add(feature)
            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end
        end
      end
    end
  end
end
