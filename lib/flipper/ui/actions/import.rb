require 'flipper/ui/action'
require 'flipper/ui/util'

module Flipper
  module UI
    module Actions
      class Import < UI::Action
        route %r{\A/settings\/import/?\Z}

        def post
          render_read_only if read_only?
          contents = params['file'][:tempfile].read
          export = Flipper::Exporters::Json::Export.new(contents: contents)
          flipper.import(export)
          redirect_to "/features"
        end
      end
    end
  end
end
