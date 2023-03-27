require 'flipper/ui/action'
require 'flipper/ui/util'

module Flipper
  module UI
    module Actions
      class Export < UI::Action
        route %r{\A/settings\/export/?\Z}

        def post
          header 'Content-Disposition', "Attachment;filename=flipper_#{flipper.adapter.adapter.name}_#{Time.now.to_i}.json"

          export = flipper.export(format: :json, version: 1)
          json_response export.contents
        end
      end
    end
  end
end
