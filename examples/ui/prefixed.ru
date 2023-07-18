#
# Usage:
#   bundle exec rackup examples/ui/prefixed.ru -p 9999
#
#   http://localhost:9999/
#
require 'bundler/setup'
require 'rack/reloader'
require "flipper/ui"
require "flipper/adapters/pstore"

use Rack::Reloader

run Rack::URLMap.new(
  "/" => lambda { |env|
    [302, {"Location" => "/flipper"}, [] ]
  },
  "/flipper" => Flipper::UI.app { |builder|
    builder.use Rack::Session::Cookie, secret: "_super_secret"
  }
)
