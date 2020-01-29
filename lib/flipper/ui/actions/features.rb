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
          @features = flipper.features.map do |feature|
            Decorators::Feature.new(feature)
          end.sort

          @show_blank_slate = @features.empty?

          init_tabs

          breadcrumb 'Home', '/'
          breadcrumb 'Features'

          view_response :features
        end

        def post
          unless Flipper::UI.configuration.feature_creation_enabled
            status 403

            breadcrumb 'Home', '/'
            breadcrumb 'Features', '/features'
            breadcrumb 'Noooooope'

            halt view_response(:feature_creation_disabled)
          end

          feature_name = params['value'].to_s.strip

          if Util.blank?(feature_name)
            error = Rack::Utils.escape("#{feature_name.inspect} is not a valid feature name.")
            redirect_to("/features/new?error=#{error}")
          end

          namespace = params['namespace'].to_s.strip
          feature_name = "#{namespace}:#{feature_name}" unless namespace.empty?
          feature = flipper[feature_name]

          feature.add

          redirect_to "/features/#{Rack::Utils.escape_path(feature_name)}"
        end

        private

        def init_tabs
          tab_names = flipper.features.map do |feature|
            feature.key.split(':').first if feature.key.include?(':')
          end.compact.uniq

          @tabs = tab_names.map do |tab_name|
            OpenStruct.new(
              name: tab_name,
              href: "#{script_name}/namespaces/#{tab_name}",
              active: false
            )
          end

          @tabs.unshift OpenStruct.new(name: 'all', href: "#{script_name}/features", active: true)
        end
      end
    end
  end
end
