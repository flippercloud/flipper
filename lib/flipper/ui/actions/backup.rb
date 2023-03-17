require 'flipper/ui/action'
require 'flipper/ui/util'

module Flipper
  module UI
    module Actions
      class Backup < UI::Action
        route %r{\A/backup/?\Z}

        def get
          @page_title = 'Backup'

          breadcrumb 'Home', '/'
          breadcrumb 'Backup'

          view_response :backup
        end

        def post
          header 'Content-Disposition', "Attachment;filename=flipper_#{flipper.adapter.adapter.name}_#{Time.now.to_i}.json"

          json_response flipper.export(format: :json, version: 1)
        end
      end
    end
  end
end
