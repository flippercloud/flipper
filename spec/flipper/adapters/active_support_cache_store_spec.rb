require 'active_support/cache'
require 'flipper/adapters/operation_logger'
require 'flipper/adapters/active_support_cache_store'

RSpec.describe Flipper::Adapters::ActiveSupportCacheStore do
  let(:memory_adapter) do
    Flipper::Adapters::OperationLogger.new(Flipper::Adapters::Memory.new)
  end
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:write_through) { false }
  let(:race_condition_ttl) { 5 }
  let(:adapter) { described_class.new(memory_adapter, cache, 10, race_condition_ttl: race_condition_ttl, write_through: write_through) }
  let(:flipper) { Flipper.new(adapter) }

  subject { adapter }

  before do
    cache.clear
  end

  it_should_behave_like 'a flipper adapter'

  it "knows ttl" do
    expect(adapter.ttl).to eq(10)
  end

  it "knows ttl when only expires_in provided" do
    silence do
      adapter = described_class.new(memory_adapter, cache, expires_in: 10)
      expect(adapter.ttl).to eq(10)
    end
  end

  it "knows ttl when ttl and expires_in are provided" do
    silence do
      adapter = described_class.new(memory_adapter, cache, 200, expires_in: 10)
      expect(adapter.ttl).to eq(10)
    end
  end

  it "knows default when no ttl or expires_in provided" do
    adapter = described_class.new(memory_adapter, cache)
    expect(adapter.ttl).to be(nil)
  end

  it "knows race_condition_ttl" do
    expect(adapter.race_condition_ttl).to eq(race_condition_ttl)
  end

  it "knows default when no ttl or expires_in provided" do
    adapter = described_class.new(memory_adapter, cache)
    expect(adapter.race_condition_ttl).to be(nil)
  end

  it "knows features_cache_key" do
    expect(adapter.features_cache_key).to eq("flipper/v1/features")
  end

  it "can expire features cache" do
    # cache the features
    adapter.features
    expect(cache.read("flipper/v1/features")).not_to be(nil)

    # expire cache
    adapter.expire_features_cache
    expect(cache.read("flipper/v1/features")).to be(nil)
  end

  it "can expire feature cache" do
    # cache the features
    adapter.get(flipper[:stats])
    expect(cache.read("flipper/v1/feature/stats")).not_to be(nil)

    # expire cache
    adapter.expire_feature_cache("stats")
    expect(cache.read("flipper/v1/feature/stats")).to be(nil)
  end

  it "can generate feature cache key" do
    expect(adapter.feature_cache_key("stats")).to eq("flipper/v1/feature/stats")
  end

  context "when using a prefix" do
    let(:adapter) { described_class.new(memory_adapter, cache, 10, prefix: "foo/") }
    it_should_behave_like 'a flipper adapter'

    it "knows features_cache_key" do
      expect(adapter.features_cache_key).to eq("foo/flipper/v1/features")
    end

    it "can generate feature cache key" do
      expect(adapter.feature_cache_key("stats")).to eq("foo/flipper/v1/feature/stats")
    end

    it "uses the prefix for all keys" do
      # check individual feature get cached with prefix
      adapter.get(flipper[:stats])
      expect(cache.read("foo/flipper/v1/feature/stats")).not_to be(nil)

      # check individual feature expired with prefix
      adapter.remove(flipper[:stats])
      expect(cache.read("foo/flipper/v1/feature/stats")).to be(nil)

      # enable some stuff
      flipper.enable_percentage_of_actors(:search, 10)
      flipper.enable(:stats)

      # populate the cache
      adapter.get_all

      # verify cached with prefix
      expect(cache.read("foo/flipper/v1/features")).to eq(Set["stats", "search"])
      expect(cache.read("foo/flipper/v1/feature/search")[:percentage_of_actors]).to eq("10")
      expect(cache.read("foo/flipper/v1/feature/stats")[:boolean]).to eq("true")
    end
  end

  describe '#remove' do
    let(:feature) { flipper[:stats] }

    before do
      adapter.get(feature)
      adapter.remove(feature)
    end

    it 'expires feature and deletes the cache' do
      expect(cache.read("flipper/v1/feature/#{feature.key}")).to be_nil
      expect(cache.exist?("flipper/v1/feature/#{feature.key}")).to be(false)
      expect(feature).not_to be_enabled
    end

    context 'with write-through caching' do
      let(:write_through) { true }

      it 'expires feature and writes an empty value to the cache' do
        expect(cache.read("flipper/v1/feature/#{feature.key}")).to eq(adapter.default_config)
        expect(cache.exist?("flipper/v1/feature/#{feature.key}")).to be(true)
        expect(feature).not_to be_enabled
      end
    end
  end

  describe '#enable' do
    let(:feature) { flipper[:stats] }

    before do
      adapter.enable(feature, feature.gate(:boolean), Flipper::Types::Boolean.new(true))
    end

    it 'enables feature and deletes the cache' do
      expect(cache.read("flipper/v1/feature/#{feature.key}")).to be_nil
      expect(cache.exist?("flipper/v1/feature/#{feature.key}")).to be(false)
      expect(feature).to be_enabled
    end

    context 'with write-through caching' do
      let(:write_through) { true }

      it 'expires feature and writes to the cache' do
        expect(cache.exist?("flipper/v1/feature/#{feature.key}")).to be(true)
        expect(cache.read("flipper/v1/feature/#{feature.key}")).to include(boolean: 'true')
        expect(feature).to be_enabled
      end
    end
  end

  describe '#disable' do
    let(:feature) { flipper[:stats] }

    before do
      adapter.disable(feature, feature.gate(:boolean), Flipper::Types::Boolean.new)
    end

    it 'disables feature and deletes the cache' do
      expect(cache.read("flipper/v1/feature/#{feature.key}")).to be_nil
      expect(cache.exist?("flipper/v1/feature/#{feature.key}")).to be(false)
      expect(feature).not_to be_enabled
    end

    context 'with write-through caching' do
      let(:write_through) { true }

      it 'expires feature and writes to the cache' do
        expect(cache.exist?("flipper/v1/feature/#{feature.key}")).to be(true)
        expect(cache.read("flipper/v1/feature/#{feature.key}")).to include(boolean: nil)
        expect(feature).not_to be_enabled
      end
    end
  end

  describe '#get_multi' do
    it 'warms uncached features' do
      stats = flipper[:stats]
      search = flipper[:search]
      other = flipper[:other]
      stats.enable
      search.enable

      memory_adapter.reset

      adapter.get(stats)
      expect(cache.read("flipper/v1/feature/#{search.key}")).to be(nil)
      expect(cache.read("flipper/v1/feature/#{other.key}")).to be(nil)

      adapter.get_multi([stats, search, other])

      expect(cache.read("flipper/v1/feature/#{search.key}")[:boolean]).to eq('true')
      expect(cache.read("flipper/v1/feature/#{other.key}")[:boolean]).to be(nil)

      adapter.get_multi([stats, search, other])
      adapter.get_multi([stats, search, other])
      expect(memory_adapter.count(:get_multi)).to eq(1)
    end
  end

  describe '#get_all' do
    let(:stats) { flipper[:stats] }
    let(:search) { flipper[:search] }

    before do
      stats.enable
      search.add
    end

    it 'warms all features' do
      adapter.get_all
      expect(cache.read("flipper/v1/feature/#{stats.key}")[:boolean]).to eq('true')
      expect(cache.read("flipper/v1/feature/#{search.key}")[:boolean]).to be(nil)
      expect(cache.read("flipper/v1/features")).to eq(Set["stats", "search"])
    end

    it 'returns same result when already cached' do
      expect(adapter.get_all).to eq(adapter.get_all)
    end

    it 'only invokes two calls to wrapped adapter (for features set and gate data for each feature in set)' do
      memory_adapter.reset
      5.times { adapter.get_all }
      expect(memory_adapter.count(:features)).to eq(1)
      expect(memory_adapter.count(:get_multi)).to eq(1)
      expect(memory_adapter.count).to eq(2)
    end
  end

  describe '#name' do
    it 'is active_support_cache_store' do
      expect(subject.name).to be(:active_support_cache_store)
    end
  end
end
