require 'rack/file'
require 'flipper/ui/action'

module Flipper
  module UI
    module Actions
      class File < UI::Action
        REGEX = %r{(images|css|js|octicons|fonts)/.*\Z}
        route REGEX

        def get
          Rack::File.new(public_path).call(request.env)
        end
      end
    end
  end
end
