if Rack.release >= "2.1"
  require 'rack/files'
else
  require 'rack/file'
end
require 'flipper/ui/action'

module Flipper
  module UI
    module Actions
      class File < UI::Action
        route %r{(images|css|js)/.*\Z}

        def get
          klass = Rack.release >= "2.1" ? Rack::Files : Rack::File
          klass.new(public_path).call(request.env)
        end
      end
    end
  end
end
