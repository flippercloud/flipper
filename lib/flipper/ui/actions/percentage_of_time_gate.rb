# frozen_string_literal: true

require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class PercentageOfTimeGate < UI::Action
        include FeatureNameFromRoute

        route %r{\A/features/(?<feature_name>.*)/percentage_of_time/?\Z}

        def post
          feature = flipper[feature_name]
          @feature = Decorators::Feature.new(feature)

          begin
            feature.enable_percentage_of_time params['value']
          rescue ArgumentError => e
            error = Rack::Utils.escape("Invalid percentage of time value: #{e.message}")
            redirect_to("/features/#{@feature.key}?error=#{error}")
          end

          redirect_to "/features/#{@feature.key}"
        end
      end
    end
  end
end
