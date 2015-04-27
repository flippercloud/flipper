require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class GroupsGate < UI::Action
        route %r{features/[^/]*/groups/?\Z}

        def get
          feature_name = Rack::Utils.unescape(request.path.split('/')[-2])
          feature = flipper[feature_name.to_sym]
          @feature = Decorators::Feature.new(feature)

          breadcrumb "Home", "/"
          breadcrumb "Features", "/features"
          breadcrumb @feature.key, "/features/#{@feature.key}"
          breadcrumb "Add Group"

          view_response :add_group
        end

        def post
          feature_name = Rack::Utils.unescape(request.path.split('/')[-2])
          feature = flipper[feature_name.to_sym]
          value = params["value"]

          case params["operation"]
          when "enable"
            feature.enable_group value
          when "disable"
            feature.disable_group value
          end

          redirect_to("/features/#{feature.key}")
        rescue Flipper::GroupNotRegistered => e
          error = Rack::Utils.escape("The group named #{value.inspect} has not been registered.")
          redirect_to("/features/#{feature.key}/groups?error=#{error}")
        end
      end
    end
  end
end
