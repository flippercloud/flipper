require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'
require 'flipper/ui/util'

module Flipper
  module UI
    module Actions
      class Features < UI::Action

        route %r{features/?\Z}

        def get
          @page_title = "Features"
          @features = flipper.features.map { |feature|
            Decorators::Feature.new(feature)
          }.sort

          @show_blank_slate = @features.empty?

          breadcrumb "Home", "/"
          breadcrumb "Features"

          view_response :features
        end

        def post
          unless Flipper::UI.feature_creation_enabled
            status 403

            breadcrumb "Home", "/"
            breadcrumb "Features", "/features"
            breadcrumb "Noooooope"

            halt view_response(:feature_creation_disabled)
          end

          value = params["value"]

          if Util.blank?(value)
            error = Rack::Utils.escape("#{value.inspect} is not a valid feature name.")
            redirect_to("/features/new?error=#{error}")
          end

          flipper.adapter.add(flipper[value])

          redirect_to "/features/#{Rack::Utils.escape_path(value)}"
        end
      end
    end
  end
end
