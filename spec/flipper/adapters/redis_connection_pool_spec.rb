require 'flipper/adapters/redis_connection_pool'

RSpec.describe Flipper::Adapters::RedisConnectionPool do
  let(:pool) do
    Redis.raise_deprecations = true
    ConnectionPool.new(size: 5, timeout: 5) {
      Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
    }
  end

  subject { described_class.new(pool) }

  before do
    skip_on_error(Redis::CannotConnectError, 'Redis not available') do
      pool.with { |conn| conn.flushdb }
    end
  end

  it_should_behave_like 'a flipper adapter'

  it 'configures itself on load' do
    Flipper.configuration = nil
    Flipper.instance = nil

    silence { load 'flipper/adapters/redis_connection_pool.rb' }

    expect(Flipper.adapter.adapter).to be_a(Flipper::Adapters::RedisConnectionPool)
  end

  describe 'with a key_prefix' do
    let(:subject) { described_class.new(pool, key_prefix: "lockbox:") }
    let(:feature) { Flipper::Feature.new(:search, subject) }

    it_should_behave_like 'a flipper adapter'

    it 'namespaces feature-keys' do
      subject.add(feature)

      pool.with do |conn|
        expect(conn.smembers("flipper_features")).to eq([])
        expect(conn.exists?("search")).to eq(false)
        expect(conn.smembers("lockbox:flipper_features")).to eq(["search"])
        expect(conn.hgetall("lockbox:search")).not_to eq(nil)
      end
    end

    it "can remove namespaced keys" do
      subject.add(feature)

      pool.with do |conn|
        expect(conn.smembers("lockbox:flipper_features")).to eq(["search"])
        subject.remove(feature)
        expect(conn.smembers("lockbox:flipper_features")).to be_empty
      end
    end
  end
end
