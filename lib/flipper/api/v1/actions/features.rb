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
            feature_name = params.fetch('name') do
              json_response({
                errors: [{
                  message: 'Missing post parameter: name',
                }]
              }, 422)
            end

            flipper.adapter.add(flipper[feature_name])
            json_response({}, 200)
          end
        end
      end
    end
  end
end
