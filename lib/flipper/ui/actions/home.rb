require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Home < UI::Action
        match do |request|
          request.path_info =~ %r{\A/?\Z}
        end

        def get
          redirect_to '/features'
        end
      end
    end
  end
end
