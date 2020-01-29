require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'
require 'flipper/ui/util'

module Flipper
  module UI
    module Actions
      class Namespaces < UI::Action
        route %r{\A/namespaces/(?<namespace>.*)\Z}

        def get
          match = request.path_info.match(self.class.route_regex)
          namespace = match ? Rack::Utils.unescape(match[:namespace]) : nil

          @page_title = 'Features'

          @features = flipper.features.map do |feature|
            if feature.key.include?(':') && feature.key.split(':').first == namespace
              Decorators::Feature.new(feature)
            end
          end.compact.sort

          @show_blank_slate = @features.empty?

          init_tabs(namespace)

          breadcrumb 'Home', '/'
          breadcrumb 'Namespaces'

          view_response :features
        end

        private

        def init_tabs(namespace)
          tab_names = flipper.features.map do |feature|
            feature.key.split(':').first if feature.key.include?(':')
          end.compact.uniq

          @tabs = tab_names.map do |tab_name|
            OpenStruct.new(
              name: tab_name,
              href: "#{script_name}/namespaces/#{tab_name}",
              active: tab_name == namespace
            )
          end

          @tabs.unshift OpenStruct.new(name: 'all', href: "#{script_name}/features", active: false)
        end
      end
    end
  end
end
