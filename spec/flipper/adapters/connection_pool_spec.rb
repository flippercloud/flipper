require "connection_pool"
require "flipper/adapters/connection_pool"
require "flipper-redis"

RSpec.describe Flipper::Adapters::ConnectionPool do
  let(:pool) do
    ConnectionPool.new(size: 1, timeout: 5) do
      Redis.new({url: ENV['REDIS_URL']}.compact)
    end
  end

  subject do
    described_class.new(pool) { |client| Flipper::Adapters::Redis.new(client) }
  end

  before do
    skip_on_error(Redis::CannotConnectError, 'Redis not available') do
      pool.with(&:flushdb)
    end
  end


  it_should_behave_like 'a flipper adapter'
end
