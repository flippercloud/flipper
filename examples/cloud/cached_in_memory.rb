require File.expand_path('../../example_setup', __FILE__)

require 'flipper/cloud'
require 'flipper/adapters/active_support_cache_store'
require 'active_support/cache'
require 'active_support/cache/memory_store'

token = ENV.fetch("TOKEN") { abort "TOKEN environment variable not set." }
feature_name = ENV.fetch("FEATURE") { "testing" }.to_sym

Flipper.configure do |config|
  config.default do
    Flipper::Cloud.new(token) do |cloud|
      cloud.debug_output = STDOUT
      cloud.adapter do |adapter|
        Flipper::Adapters::ActiveSupportCacheStore.new(adapter,
          ActiveSupport::Cache::MemoryStore.new, {expires_in: 5.seconds})
      end
    end
  end
end

loop do
  # Should only print out http call every 5 seconds
  p Flipper.enabled?(feature_name)
  puts "\n\n"

  sleep 1
end
