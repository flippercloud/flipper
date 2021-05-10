#
# Usage:
#   # if you want it to not reload and be really fast
#   bin/rackup examples/api/custom_memoized.ru -p 9999
#
#   # if you want reloading
#   bin/shotgun examples/api/custom_memoized.ru -p 9999
#
#   http://localhost:9999/
#

require 'bundler/setup'
require "active_support/notifications"
require "flipper/api"
require "flipper/adapters/pstore"

adapter = Flipper::Adapters::Instrumented.new(
  Flipper::Adapters::PStore.new,
  instrumenter: ActiveSupport::Notifications,
)
flipper = Flipper.new(adapter)

ActiveSupport::Notifications.subscribe(/.*/, ->(*args) {
  p args: args
})

Flipper.register(:admins) { |actor|
  actor.respond_to?(:admin?) && actor.admin?
}

# You can uncomment this to get some default data:
# flipper[:logging].enable_percentage_of_time 5

run Flipper::Api.app(flipper) { |builder|
  builder.use Flipper::Middleware::SetupEnv, flipper, env_key: "flipper_api"
  builder.use Flipper::Middleware::Memoizer, env_key: "flipper_api", preload: true
}
