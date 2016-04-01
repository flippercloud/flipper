require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class Features < Api::Action
          route %r{api/v1/features/}

          def get
            features = flipper.features.map do |feature|
              V1::Decorators::Feature.new(feature)
            end
            json_response({features: features})
          end

        end
      end
    end
  end
end
