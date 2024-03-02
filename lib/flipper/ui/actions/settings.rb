require 'flipper/ui/action'
require 'flipper/ui/util'

module Flipper
  module UI
    module Actions
      class Settings < UI::Action
        route %r{\A/settings/?\Z}

        def get
          @page_title = 'Settings'

          view_response :settings
        end
      end
    end
  end
end
