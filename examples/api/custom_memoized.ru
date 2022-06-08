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
require 'active_support'
require 'active_support/notifications'
require "flipper/api"
require "flipper/adapters/pstore"

Flipper.configure do |config|
  config.instrumenter ActiveSupport::Notifications
  config.adapter { Flipper::Adapters::Instrumented.new(Flipper::Adapters::PStore.new) }
end

ActiveSupport::Notifications.subscribe(/.*/, ->(*args) {
  name, start, finish, id, data = args
  case name
  when "adapter_operation.flipper"
    p data[:adapter_name] => data[:operation]
  end
})

# You can uncomment this to get some default data:
# flipper[:logging].enable_percentage_of_time 5

run Flipper::Api.app { |builder|
  builder.use Flipper::Middleware::Memoizer, preload: true
}
