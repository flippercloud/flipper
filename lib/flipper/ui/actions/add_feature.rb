require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class AddFeature < UI::Action
        route %r{\A/features/new/?\Z}

        def get
          render_read_only if read_only?

          unless Flipper::UI.configuration.feature_creation_enabled
            status 403
            halt view_response(:feature_creation_disabled)
          end

          view_response :add_feature
        end
      end
    end
  end
end
