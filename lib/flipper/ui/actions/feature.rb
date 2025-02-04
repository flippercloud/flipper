require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Feature < UI::Action
        include FeatureNameFromRoute

        route %r{\A/features/(?<feature_name>.*)\Z}

        def get
          flipper_feature = flipper[feature_name]
          @feature = Decorators::Feature.new(flipper_feature)
          descriptions = Flipper::UI.configuration.descriptions_source.call([flipper_feature.key])
          @feature.description = descriptions[@feature.key]
          @feature.actor_names = Flipper::UI.configuration.actor_names_source.call(@feature.actors_value)
          @page_title = "#{@feature.key} // Features"
          @percentages = [0, 1, 5, 10, 25, 50, 100]

          view_response :feature
        end

        def delete
          render_read_only if read_only?

          unless Flipper::UI.configuration.feature_removal_enabled
            status 403

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
