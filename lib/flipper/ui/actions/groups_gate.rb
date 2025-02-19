require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class GroupsGate < UI::Action
        include FeatureNameFromRoute

        route %r{\A/features/(?<feature_name>.*)/groups/?\Z}

        def get
          feature = flipper[feature_name]
          @feature = Decorators::Feature.new(feature)

          view_response :add_group
        end

        def post
          render_read_only if read_only?

          feature = flipper[feature_name]
          value = params['value'].to_s.strip

          if Flipper.group_exists?(value)
            case params['operation']
            when 'enable'
              feature.enable_group value
            when 'disable'
              feature.disable_group value
            end

            redirect_to("/features/#{Flipper::UI::Util.escape feature.key}")
          else
            error = "The group named #{value.inspect} has not been registered."
            redirect_to("/features/#{Flipper::UI::Util.escape feature.key}/groups?error=#{Flipper::UI::Util.escape error}")
          end
        end
      end
    end
  end
end
