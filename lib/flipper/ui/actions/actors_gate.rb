require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'
require 'flipper/ui/util'

module Flipper
  module UI
    module Actions
      class ActorsGate < UI::Action
        route %r{features/[^/]*/actors/?\Z}

        def get
          feature_name = Rack::Utils.unescape(request.path.split('/')[-2])
          feature = flipper[feature_name.to_sym]
          @feature = Decorators::Feature.new(feature)

          breadcrumb "Home", "/"
          breadcrumb "Features", "/features"
          breadcrumb @feature.key, "/features/#{@feature.key}"
          breadcrumb "Add Actor"

          view_response :add_actor
        end

        def post
          feature_name = Rack::Utils.unescape(request.path.split('/')[-2])
          feature = flipper[feature_name.to_sym]
          value = params["value"]

          if Util.blank?(value)
            error = Rack::Utils.escape("#{value.inspect} is not a valid actor value.")
            redirect_to("/features/#{feature.key}/actors?error=#{error}")
          end

          actor = Flipper::UI::Actor.new(value)

          case params["operation"]
          when "enable"
            feature.enable_actor actor
          when "disable"
            feature.disable_actor actor
          end

          redirect_to("/features/#{feature.key}")
        end
      end
    end
  end
end
