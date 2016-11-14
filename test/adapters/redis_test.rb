require 'test_helper'
require 'flipper/test/shared_adapter_test'
require 'flipper/adapters/redis'

class RedisTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  def setup
    DataStores.reset_redis
    @adapter = Flipper::Adapters::Redis.new(DataStores.redis)
  end
end
