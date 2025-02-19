require 'test_helper'
require 'flipper/adapters/redis'

class RedisConnectionPoolTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  def setup
    url = ENV.fetch('REDIS_URL', 'redis://localhost:6379')
    pool = ConnectionPool.new(size: 5, timeout: 5) {
      Redis.new(url: url)
    }
    @adapter = Flipper::Adapters::RedisConnectionPool.new(pool)
    pool.with { |client| client.flushdb }
  rescue Redis::CannotConnectError
    ENV['CI'] ? raise : skip('Redis not available')
  end
end
