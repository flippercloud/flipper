# This is an example of using cloud with a local adapter. All cloud feature
# changes are synced to the local adapter on an interval. All feature reads are
# directed to the local adapter, which means reads are fast and not dependent on
# cloud being available. You can turn internet on/off and more and this should
# never raise. You could get a slow request every now and then if cloud is
# unavailable, but we are hoping to fix that soon by doing the cloud update in a
# background thread.
# env FLIPPER_CLOUD_TOKEN=<token> bundle exec ruby examples/cloud/local_adapter.rb
require File.expand_path('../../example_setup', __FILE__)

require 'logger'
require 'flipper/cloud'
require 'flipper/adapters/redis'

feature_name = ENV.fetch("FEATURE") { "testing" }.to_sym

redis = Redis.new(logger: Logger.new(STDOUT))
redis.flushdb

Flipper.configure do |config|
  config.default do
    Flipper::Cloud.new do |cloud|
      cloud.debug_output = STDOUT
      cloud.local_adapter = Flipper::Adapters::Redis.new(redis)
      cloud.sync_interval = 10
    end
  end
end

loop do
  # Should only print out http call every 10 seconds
  p Flipper.enabled?(feature_name)
  puts "\n\n"

  sleep 1
end
