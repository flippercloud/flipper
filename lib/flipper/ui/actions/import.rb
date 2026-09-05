require 'flipper/ui/action'
require 'flipper/ui/util'

module Flipper
  module UI
    module Actions
      class Import < UI::Action
        route %r{\A/settings\/import/?\Z}

        def post
          render_read_only if read_only?

          file = params['file']
          unless file.is_a?(Hash) && file[:tempfile]
            redirect_to_settings("You must select a file to import.")
          end

          tempfile = file[:tempfile]
          if tempfile.size > Flipper::Exporters::Json::Export::MAX_BYTES
            redirect_to_settings("The import file is too large to import.")
          end

          export = Flipper::Exporters::Json::Export.new(contents: tempfile.read)
          flipper.import(export)
          redirect_to "/features"
        rescue Flipper::Exporters::Json::InvalidError
          redirect_to_settings("The import file is invalid.")
        end

        private

        def redirect_to_settings(error)
          redirect_to "/settings?error=#{Flipper::UI::Util.escape(error)}"
        end
      end
    end
  end
end
