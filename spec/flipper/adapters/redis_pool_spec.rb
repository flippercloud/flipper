require 'flipper/adapters/redis_pool'

RSpec.describe Flipper::Adapters::RedisPool do
  subject do
    pool = ConnectionPool.new(size: 1, &create_client)
    described_class.new(pool, key_prefix: key_prefix)
  end

  it_behaves_like "a redis adapter"
end
