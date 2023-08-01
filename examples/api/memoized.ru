#
# Usage:
#   bin/rackup examples/api/memoized.ru -p 9999
#
#   http://localhost:9999/
#

require 'bundler/setup'
require 'rack/reloader'
require "active_support/notifications"
require "flipper/api"
require "flipper/adapters/pstore"

Flipper.configure do |config|
  config.adapter {
    Flipper::Adapters::Instrumented.new(
      Flipper::Adapters::PStore.new,
      instrumenter: ActiveSupport::Notifications,
    )
  }
end

ActiveSupport::Notifications.subscribe(/.*/, ->(*args) {
  name, start, finish, id, data = args
  case name
  when "adapter_operation.flipper"
    p data[:adapter_name] => data[:operation]
  end
})

Flipper.register(:admins) { |actor|
  actor.respond_to?(:admin?) && actor.admin?
}

# You can uncomment this to get some default data:
# Flipper.enable :logging

use Rack::Reloader

run Flipper::Api.app { |builder|
  builder.use Flipper::Middleware::Memoizer, preload: true
}
