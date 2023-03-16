require_relative "./ar_setup"

# Requires the flipper-active_record gem to be installed.
require 'flipper/adapters/active_record'
require 'flipper/adapters/active_support_cache_store'

Flipper.configure do |config|
  config.adapter do
    Flipper::Adapters::ActiveSupportCacheStore.new(
      Flipper::Adapters::ActiveRecord.new,
      ActiveSupport::Cache::MemoryStore.new,
      expires_in: 2.seconds
    )
  end
end

ActiveRecord::Base.logger = Logger.new(STDOUT)

puts "You should see 5 or 6 queries."
10.times do |i|
  Flipper.enabled?(:foo)
  sleep 1
end
