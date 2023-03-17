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
          features = flipper.adapter.get_all

          features.each do |feature_key, gates|
            gates.each do |key, value|
              case value
              when Set
                features[feature_key][key] = value.to_a
              end
            end
          end

          header 'Content-Disposition', "Attachment;filename=flipper_#{flipper.adapter.adapter.name}_#{Time.now.to_i}.json"

          json_response({
            version: 1,
            features: features,
          })
        end
      end
    end
  end
end
