require 'rack/file'
require 'flipper/ui/action'

module Flipper
  module UI
    module Actions
      class File < UI::Action
        match do |request|
          request.path_info =~ %r{(images|css|js|octicons|fonts)/.*\Z}
        end

        def get
          Rack::File.new(public_path).call(request.env)
        end
      end
    end
  end
end
