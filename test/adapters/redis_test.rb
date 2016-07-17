require 'test_helper'
require 'flipper/adapters/redis'

class RedisTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  def setup
   client = Redis.new
   client.flushdb
   @adapter = Flipper::Adapters::Redis.new(client)
  end
end
