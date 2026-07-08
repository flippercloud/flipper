require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class DenyGroupsGate < UI::Action
        include FeatureNameFromRoute

        route %r{\A/features/(?<feature_name>.*)/deny_groups/?\Z}

        def post
          render_read_only if read_only?

          feature = flipper[feature_name]
          value = params['value'].to_s.strip

          if Flipper.group_exists?(value)
            case params['operation']
            when 'deny'
              feature.deny_group value
            when 'permit'
              feature.permit_group value
            end

            redirect_to("/features/#{Flipper::UI::Util.escape feature.key}")
          else
            error = "The group named #{value.inspect} has not been registered."
            redirect_to("/features/#{Flipper::UI::Util.escape feature.key}/deny_groups?error=#{Flipper::UI::Util.escape error}")
          end
        end
      end
    end
  end
end
