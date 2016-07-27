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
        end
      end
    end
  end
end
