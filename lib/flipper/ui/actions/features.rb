require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'
require 'flipper/ui/util'

module Flipper
  module UI
    module Actions
      class Features < UI::Action
        route %r{\A/features/?\Z}

        def get
          @page_title = 'Features'
          keys = flipper.features.map(&:key)
          descriptions = if Flipper::UI.configuration.show_feature_description_in_list?
            Flipper::UI.configuration.descriptions_source.call(keys)
          else
            {}
          end

          @features = flipper.features.map do |feature|
            decorated_feature = Decorators::Feature.new(feature)

            if Flipper::UI.configuration.show_feature_description_in_list?
              decorated_feature.description = descriptions[feature.key]
            end

            decorated_feature
          end.sort

          @show_blank_slate = @features.empty?

          view_response :features
        end

        def post
          render_read_only if read_only?

          unless Flipper::UI.configuration.feature_creation_enabled
            status 403

            halt view_response(:feature_creation_disabled)
          end

          value = params['value'].to_s.strip

          if Util.blank?(value)
            error = "#{value.inspect} is not a valid feature name."
            redirect_to("/features/new?error=#{Flipper::UI::Util.escape error}")
          end

          feature = flipper[value]
          feature.add

          redirect_to "/features/#{Flipper::UI::Util.escape value}"
        end
      end
    end
  end
end
