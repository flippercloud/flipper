require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class BooleanGate < UI::Action
        include FeatureNameFromRoute

        route %r{\A/features/(?<feature_name>.*)/boolean/?\Z}

        def post
          feature = feature_name.to_sym
          @feature = Decorators::Feature.new(flipper[feature])

          if params['action'] == 'Enable'
            flipper.enable(feature)
          else
            flipper.disable(feature)
          end

          redirect_to "/features/#{@feature.key}"
        end
      end
    end
  end
end
