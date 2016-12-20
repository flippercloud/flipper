require 'test_helper'
require 'flipper/adapters/redis'

class RedisTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  def setup
    url = ENV.fetch('BOXEN_REDIS_URL', 'localhost:6379')
   client = Redis.new({url: url}).tap { |c| c.flushdb }
   @adapter = Flipper::Adapters::Redis.new(client)
  end
end
