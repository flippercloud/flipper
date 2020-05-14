require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Feature < UI::Action
        include FeatureNameFromRoute

        route %r{\A/features/(?<feature_name>.*)\Z}

        def get
          @feature = Decorators::Feature.new(flipper[feature_name])
          descriptions = Flipper::UI.configuration.descriptions_source
          @feature.description = descriptions[@feature.key]
          @page_title = "#{@feature.key} // Features"
          @percentages = [0, 1, 5, 10, 15, 25, 50, 75, 100]

          breadcrumb 'Home', '/'
          breadcrumb 'Features', '/features'
          breadcrumb @feature.key

          view_response :feature
        end

        def delete
          unless Flipper::UI.configuration.feature_removal_enabled
            status 403

            breadcrumb 'Home', '/'
            breadcrumb 'Features', '/features'

            halt view_response(:feature_removal_disabled)
          end

          feature = flipper[feature_name]
          feature.remove
          redirect_to '/features'
        end
      end
    end
  end
end
