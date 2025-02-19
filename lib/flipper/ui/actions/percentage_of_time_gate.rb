require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class PercentageOfTimeGate < UI::Action
        include FeatureNameFromRoute

        route %r{\A/features/(?<feature_name>.*)/percentage_of_time/?\Z}

        def post
          render_read_only if read_only?

          feature = flipper[feature_name]
          @feature = Decorators::Feature.new(feature)

          begin
            feature.enable_percentage_of_time params['value']
          rescue ArgumentError => exception
            error = "Invalid percentage of time value: #{exception.message}"
            redirect_to("/features/#{Flipper::UI::Util.escape @feature.key}?error=#{Flipper::UI::Util.escape error}")
          end

          redirect_to "/features/#{Flipper::UI::Util.escape @feature.key}"
        end
      end
    end
  end
end
