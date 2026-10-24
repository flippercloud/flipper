require 'flipper/adapters/redis'
require 'connection_pool'

RSpec.shared_examples 'a redis adapter that protects its feature list' do
  it 'refuses writes to a feature named flipper_features' do
    subject.add(Flipper::Feature.new(:search, subject))
    feature = Flipper::Feature.new(:flipper_features, subject)
    boolean = feature.gate(:boolean)
    actor = feature.gate(:actor)

    [
      -> { subject.add(feature) },
      -> { subject.enable(feature, boolean, Flipper::Types::Boolean.new(true)) },
      -> { subject.enable(feature, actor, Flipper::Types::Actor.new(Flipper::Actor.new("User;1"))) },
      -> { subject.disable(feature, boolean, Flipper::Types::Boolean.new(false)) },
      -> { subject.clear(feature) },
      -> { subject.remove(feature) },
    ].each do |write|
      expect(write).to raise_error(ArgumentError, /"flipper_features" is reserved/)
    end

    expect(subject.features).to eq(Set["search"])
    expect(subject.get_all.keys).to eq(["search"])
  end
end

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
    it_should_behave_like 'a redis adapter that protects its feature list'

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
      it_should_behave_like 'a redis adapter that protects its feature list'

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
