require 'flipper/adapters/redis'
require 'connection_pool'

RSpec.describe Flipper::Adapters::Redis do
  context "redis instance" do
    let(:client) do
      Redis.raise_deprecations = true
      Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
    end

    subject { described_class.new(client) }

    before do
      skip_on_error(Redis::CannotConnectError, 'Redis not available') do
        client.flushdb
      end
    end

    it_should_behave_like 'a flipper adapter'

    it 'configures itself on load' do
      Flipper.configuration = nil
      Flipper.instance = nil

      silence { load 'flipper/adapters/redis.rb' }

      expect(Flipper.adapter.adapter).to be_a(Flipper::Adapters::Redis)
    end

    describe 'with a key_prefix' do
      let(:subject) { described_class.new(client, key_prefix: "lockbox:") }
      let(:feature) { Flipper::Feature.new(:search, subject) }

      it_should_behave_like 'a flipper adapter'

      it 'namespaces feature-keys' do
        subject.add(feature)

        expect(client.smembers("flipper_features")).to eq([])
        expect(client.exists?("search")).to eq(false)
        expect(client.smembers("lockbox:flipper_features")).to eq(["search"])
        expect(client.hgetall("lockbox:search")).not_to eq(nil)
      end

      it "can remove namespaced keys" do
        subject.add(feature)
        expect(client.smembers("lockbox:flipper_features")).to eq(["search"])

        subject.remove(feature)
        expect(client.smembers("lockbox:flipper_features")).to be_empty
      end
    end
  end

  context "with a connection pool instance" do
    let(:client) do
      Redis.raise_deprecations = true
      ConnectionPool.new(size: 1, timeout: 1) {
        Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
      }
    end

    subject { described_class.new(client) }

    before do
      skip_on_error(Redis::CannotConnectError, 'Redis not available') do
        client.with { |conn| conn.flushdb }
      end
    end

    it_should_behave_like 'a flipper adapter'

    describe 'with a key_prefix' do
      let(:subject) { described_class.new(client, key_prefix: "lockbox:") }
      let(:feature) { Flipper::Feature.new(:search, subject) }

      it_should_behave_like 'a flipper adapter'

      it 'namespaces feature-keys' do
        subject.add(feature)

        client.with do |conn|
          expect(conn.smembers("flipper_features")).to eq([])
          expect(conn.exists?("search")).to eq(false)
          expect(conn.smembers("lockbox:flipper_features")).to eq(["search"])
          expect(conn.hgetall("lockbox:search")).not_to eq(nil)
        end
      end

      it "can remove namespaced keys" do
        client.with do |conn|
          subject.add(feature)
          expect(conn.smembers("lockbox:flipper_features")).to eq(["search"])

          subject.remove(feature)
          expect(conn.smembers("lockbox:flipper_features")).to be_empty
        end
      end
    end
  end
end
