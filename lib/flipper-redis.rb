require 'flipper/adapters/redis'

Flipper.configure do |config|
  config.default do
    client = Redis.new(url: ENV["FLIPPER_REDIS_URL"] || ENV["REDIS_URL"])
    Flipper.new(Flipper::Adapters::Redis.new(client))
  end
end
