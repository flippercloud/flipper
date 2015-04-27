require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class BooleanGate < UI::Action
        route %r{features/[^/]*/boolean/?\Z}

        def post
          feature_name = Rack::Utils.unescape(request.path.split("/")[-2])
          feature = flipper[feature_name.to_sym]
          @feature = Decorators::Feature.new(feature)

          if params["action"] == "Enable"
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
