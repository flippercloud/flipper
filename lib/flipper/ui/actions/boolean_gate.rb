require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class BooleanGate < UI::Action
        REGEX = %r{\A/features/(?<feature_name>.*)/boolean/?\Z}
        route REGEX

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

        private

        def feature_name
          @feature_name ||= begin
            match = request.path_info.match(REGEX)
            match ? match[:feature_name] : nil
          end
        end
      end
    end
  end
end
