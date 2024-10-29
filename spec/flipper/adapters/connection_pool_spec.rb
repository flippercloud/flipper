require "connection_pool"
require "flipper/adapters/connection_pool"
require "flipper-redis"

RSpec.describe Flipper::Adapters::ConnectionPool do
  let(:redis_options) { {url: ENV['REDIS_URL']}.compact }

  before do
    skip_on_error(Redis::CannotConnectError, 'Redis not available') do
      Redis.new(redis_options).flushdb
    end
  end

  context "with an existing pool" do
    let(:pool) do
      ConnectionPool.new(size: 1, timeout: 5) { Redis.new(redis_options) }
    end

    subject do
      described_class.new(pool) { |client| Flipper::Adapters::Redis.new(client) }
    end

    it_should_behave_like 'a flipper adapter'

    it "should reset the cache when the pool is reloaded or shutdown" do
      subject.get_all
      expect { pool.reload { |_| } }.to change { subject.pool.instance_variable_get(:@instances).size }.from(1).to(0)
      subject.get_all
      expect { pool.shutdown { |_| } }.to change { subject.pool.instance_variable_get(:@instances).size }.from(1).to(0)
    end
  end

  context "with a new pool" do
    subject do
      described_class.new(size: 2) { Flipper::Adapters::Redis.new(Redis.new(redis_options)) }
    end

    it_should_behave_like 'a flipper adapter'
  end
end
