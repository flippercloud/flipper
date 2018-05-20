require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Feature < UI::Action
        REGEX = %r{\A/features/(.*)\Z}
        match { |request| request.path_info =~ REGEX }

        def get
          @feature = Decorators::Feature.new(flipper[feature_name])
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

        private

        def feature_name
          @feature_name ||= begin
            match = request.path_info.match(REGEX)
            match ? match[1] : nil
          end
        end
      end
    end
  end
end
