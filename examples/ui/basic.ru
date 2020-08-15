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
require "active_support/notifications"

Flipper.register(:admins) { |actor|
  actor.respond_to?(:admin?) && actor.admin?
}

Flipper.register(:early_access) { |actor|
  actor.respond_to?(:early?) && actor.early?
}

# Setup logging of flipper calls.
if ENV["LOG"] == "1"
  $logger = Logger.new(STDOUT)
  require "flipper/instrumentation/log_subscriber"
  Flipper::Instrumentation::LogSubscriber.logger = $logger
end

adapter = Flipper::Adapters::PStore.new
flipper = Flipper.new(adapter, instrumenter: ActiveSupport::Notifications)

Flipper::UI.configure do |config|
  # config.banner_text = 'Production Environment'
  # config.banner_class = 'danger'
  config.feature_creation_enabled = true
  config.feature_removal_enabled = true
  # config.show_feature_description_in_list = true
  config.descriptions_source = lambda do |_keys|
    {
      "search_performance_another_long_thing" => "Just to test feature name length.",
      "gauges_tracking" => "Should we track page views with gaug.es.",
      "unused" => "Not used.",
      "suits" => "Are suits necessary in business?",
      "secrets" => "Secrets are lies.",
      "logging" => "Log all the things.",
      "new_cache" => "Like the old cache but newer.",
      "a/b" => "Why would someone use a slash? I don't know but someone did. Let's make this really long so they regret using slashes. Please don't use slashes.",
    }
  end
end

# You can uncomment these to get some default data:
# flipper[:search_performance_another_long_thing].enable
# flipper[:gauges_tracking].enable
# flipper[:unused].disable
# flipper[:suits].enable_actor Flipper::Actor.new('1')
# flipper[:suits].enable_actor Flipper::Actor.new('6')
# flipper[:secrets].enable_group :admins
# flipper[:secrets].enable_group :early_access
# flipper[:logging].enable_percentage_of_time 5
# flipper[:new_cache].enable_percentage_of_actors 15
# flipper["a/b"].add

run Flipper::UI.app(flipper) { |builder|
  builder.use Rack::Session::Cookie, secret: "_super_secret"
}
