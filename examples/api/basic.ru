#
# Usage:
#   bin/rackup examples/api/basic.ru -p 9999
#
#   http://localhost:9999/
#

require 'bundler/setup'
require 'rack/reloader'
require "flipper/api"
require "flipper/adapters/pstore"

# You can uncomment this to get some default data:
# Flipper.enable :logging

use Rack::Reloader

run Flipper::Api.app
