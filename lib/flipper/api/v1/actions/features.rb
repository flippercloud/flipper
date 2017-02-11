require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class Features < Api::Action
          route(/features\Z/)

          def get
            keys = params['keys']
            features = if keys
                         names = keys.split(',')
                         if names.empty?
                           []
                         else
                           flipper.preload(names)
                         end
                       else
                         flipper.features
                       end

            decorated_features = features.map do |feature|
              Decorators::Feature.new(feature).as_json
            end

            json_response(features: decorated_features)
          end

          def post
            feature_name = params.fetch('name') { json_error_response(:name_invalid) }
            feature = flipper[feature_name]
            flipper.adapter.add(feature)
            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end
        end
      end
    end
  end
end
