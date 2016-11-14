require 'test_helper'
require 'flipper/test/v2_shared_adapter_test'
require 'flipper/adapters/v2/redis'

class V2RedisTest < MiniTest::Test
  prepend Flipper::Test::V2SharedAdapterTests

  def setup
    DataStores.reset_redis
    @adapter = Flipper::Adapters::V2::Redis.new(DataStores.redis)
  end
end
