RSpec.shared_examples "a redis adapter" do
  let(:create_client) do
    Proc.new do
      options = {}

      options[:url] = ENV['REDIS_URL'] if ENV['REDIS_URL']

      Redis.raise_deprecations = true
      Redis.new(options)
    end
  end
  let(:client) { create_client.call }
  let(:key_prefix) { nil }

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

    expect(Flipper.adapter.adapter).to be_a(described_class)
  end

  describe 'with a key_prefix' do
    let(:feature) { Flipper::Feature.new(:search, subject) }
    let(:key_prefix) { "lockbox:" }

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
