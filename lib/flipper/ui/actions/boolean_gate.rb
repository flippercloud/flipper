require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class BooleanGate < UI::Action
        REGEX = %r{\A/features/(.*)/boolean/?\Z}
        match { |request| request.path_info =~ REGEX }

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
            match ? match[1] : nil
          end
        end
      end
    end
  end
end
