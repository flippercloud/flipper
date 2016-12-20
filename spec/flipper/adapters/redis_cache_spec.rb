require 'helper'
require 'flipper/adapters/redis_cache'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::RedisCache do
  let(:client) {
    options = {}

    if ENV['BOXEN_REDIS_URL']
      options[:url] = ENV['BOXEN_REDIS_URL']
    end

    Redis.new(options)
  }

  let(:memory_adapter) { Flipper::Adapters::Memory.new }
  let(:cache)   { Redis.new({url: ENV.fetch('BOXEN_REDIS_URL', 'localhost:6379')})}
  let(:adapter) { Flipper::Adapters::RedisCache.new(memory_adapter, cache) }
  let(:flipper) { Flipper.new(adapter) }

  subject { described_class.new(adapter, cache) }

  before do
    client.flushdb
  end

  it_should_behave_like 'a flipper adapter'

  describe "#remove", :focus do
    it "expires feature" do
      feature = flipper[:stats]
      adapter.get(feature)
      adapter.remove(feature)
      expect(cache.get(described_class.key_for(feature))).to be(nil)
    end
  end

  describe "#get_multi" do
    it "warms uncached features" do
      stats = flipper[:stats]
      search = flipper[:search]
      other = flipper[:other]
      stats.enable
      search.enable

      adapter.get(stats)
      expect(cache.get(described_class.key_for(search))).to be(nil)
      expect(cache.get(described_class.key_for(other))).to be(nil)

      adapter.get_multi([stats, search, other])

      expect(cache.get(described_class.key_for(search))[:boolean]).to eq("true")
      expect(cache.get(described_class.key_for(other))[:boolean]).to be(nil)
    end
  end

  describe "#name" do
    it "is dalli" do
      expect(subject.name).to be(:dalli)
    end
  end
end
