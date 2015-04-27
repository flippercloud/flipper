require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class AddFeature < UI::Action
        route %r{features/new/?\Z}

        def get
          breadcrumb "Home", "/"
          breadcrumb "Features", "/features"
          breadcrumb "Add"

          view_response :add_feature
        end
      end
    end
  end
end
