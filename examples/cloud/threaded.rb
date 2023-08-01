# Usage (from the repo root):
# env FLIPPER_CLOUD_TOKEN=<token> bundle exec ruby examples/cloud/threaded.rb

require_relative "./cloud_setup"
require 'bundler/setup'
require 'flipper/cloud'
require "active_support/notifications"
require "active_support/isolated_execution_state"

ActiveSupport::Notifications.subscribe(/poller\.flipper/) do |*args|
  p args: args
end

Flipper.configure do |config|
  config.default {
    Flipper::Cloud.new(local_adapter: config.adapter, instrumenter: ActiveSupport::Notifications)
  }
end

# Check every second to see if the feature is enabled
threads = []
10.times do
  threads << Thread.new do
    loop do
      sleep rand

      if Flipper[:stats].enabled?
        puts "#{Time.now.to_i} Enabled!"
      else
        puts "#{Time.now.to_i} Disabled!"
      end
    end
  end
end

threads.map(&:join)
