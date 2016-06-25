require 'test_helper'
require 'flipper/adapters/redis'

class RedisTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  def setup
   client = Redis.new({}).tap { |c| c.flushdb }
   @adapter = Flipper::Adapters::Redis.new(client)
  end
end
