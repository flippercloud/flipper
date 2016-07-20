#
# Usage:
#   bundle exec rackup examples/ui/basic.ru -p 9999
#   bundle exec shotgun examples/ui/basic.ru -p 9999
#   http://localhost:9999/
#
require "pp"
require "logger"
require "pathname"

root_path = Pathname(__FILE__).dirname.join("..").expand_path
lib_path  = root_path.join("lib")
$:.unshift(lib_path)

require "flipper-ui"
require "flipper/adapters/pstore"

Flipper.register(:admins) { |actor|
  actor.respond_to?(:admin?) && actor.admin?
}

Flipper.register(:early_access) { |actor|
  actor.respond_to?(:early?) && actor.early?
}

# Setup logging of flipper calls.
$logger = Logger.new(STDOUT)
require "active_support/notifications"
require "flipper/instrumentation/log_subscriber"
Flipper::Instrumentation::LogSubscriber.logger = $logger

adapter = Flipper::Adapters::PStore.new
flipper = Flipper.new(adapter, instrumenter: ActiveSupport::Notifications)

# You can uncomment these to get some default data:
# flipper[:search_performance_another_long_thing].enable
# flipper[:gauges_tracking].enable
# flipper[:unused].disable
# flipper[:suits].enable_actor Flipper::UI::Actor.new('1')
# flipper[:suits].enable_actor Flipper::UI::Actor.new('6')
# flipper[:secrets].enable_group :admins
# flipper[:secrets].enable_group :early_access
# flipper[:logging].enable_percentage_of_time 5
# flipper[:new_cache].enable_percentage_of_actors 15

run Flipper::UI.app(flipper) { |builder|
  builder.use Rack::Session::Cookie, secret: "_super_secret"
}
