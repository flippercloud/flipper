require 'test_helper'
require 'flipper/adapters/redis_pool'

class RedisPoolTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  def setup
    url = ENV.fetch('REDIS_URL', 'redis://localhost:6379')
    pool = ConnectionPool.new(size: 1) { Redis.new(url: url) }
    pool.with { |client| client.flushdb }
    @adapter = Flipper::Adapters::RedisPool.new(pool)
  rescue Redis::CannotConnectError
    ENV['CI'] ? raise : skip('Redis not available')
  end
end
