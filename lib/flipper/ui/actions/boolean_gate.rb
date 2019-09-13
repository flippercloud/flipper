require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class BooleanGate < UI::Action
        include FeatureNameFromRoute

        route %r{\A/features/(?<feature_name>.*)/boolean/?\Z}

        def post
          feature = flipper[feature_name]
          @feature = Decorators::Feature.new(feature)

          if params['action'] == 'Enable'
            feature.enable
          else
            feature.disable
          end

          redirect_to "/features/#{@feature.key}"
        end
      end
    end
  end
end
