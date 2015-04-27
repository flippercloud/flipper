require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class PercentageOfTimeGate < UI::Action
        route %r{features/[^/]*/percentage_of_time/?\Z}

        def post
          feature_name = Rack::Utils.unescape(request.path.split("/")[-2])
          feature = flipper[feature_name.to_sym]
          @feature = Decorators::Feature.new(feature)

          begin
            feature.enable_percentage_of_time params["value"]
          rescue ArgumentError => exception
            error = Rack::Utils.escape("Invalid percentage of time value: #{exception.message}")
            redirect_to("/features/#{@feature.key}?error=#{error}")
          end

          redirect_to "/features/#{@feature.key}"
        end
      end
    end
  end
end
