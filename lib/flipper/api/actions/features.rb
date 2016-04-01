require 'flipper/api/action'
require 'flipper/api/decorators/feature'

module Flipper
  module Api
    module Actions
      class Features < Api::Action
        route %r{api/v1/features/}
        
        def get
          features = flipper.features.map do |feature|
            Decorators::Feature.new(feature)
          end
          json_response({features: features})
        end

      end
    end
  end
end
