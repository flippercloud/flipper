require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class PercentageOfTimeGate < UI::Action
        REGEX = %r{\A/features/(.*)/percentage_of_time/?\Z}
        match { |request| request.path_info =~ REGEX }

        def post
          feature = flipper[feature_name]
          @feature = Decorators::Feature.new(feature)

          begin
            feature.enable_percentage_of_time params['value']
          rescue ArgumentError => exception
            error = Rack::Utils.escape("Invalid percentage of time value: #{exception.message}")
            redirect_to("/features/#{@feature.key}?error=#{error}")
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
