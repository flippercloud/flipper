require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class Features < Api::Action
          route %r{\A/features/?\Z}

          def get
            keys = params['keys']
            features = if keys
              names = keys.split(',')
              if names.empty?
                []
              else
                existing_feature_names = names.keep_if do |feature_name|
                  feature_exists?(feature_name)
                end

                flipper.preload(existing_feature_names)
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
            feature.add
            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          private

          def feature_exists?(feature_name)
            flipper.features.map(&:key).include?(feature_name)
          end
        end
      end
    end
  end
end
