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

  it "passes race_condition_ttl to the cache when writing" do
    expect(cache).to receive(:fetch)
      .with(anything, hash_including(race_condition_ttl: race_condition_ttl))
      .and_call_original
    adapter.get(flipper[:stats])
  end

  it "does not pass race_condition_ttl to the cache when not configured" do
    adapter = described_class.new(memory_adapter, cache, 10)
    expect(cache).to receive(:fetch)
      .with(anything, hash_excluding(:race_condition_ttl))
      .and_call_original
    adapter.get(flipper[:stats])
  end

  it "knows features_cache_key" do
    expect(adapter.features_cache_key).to eq("flipper/v1/features")
  end

  it "can expire features cache" do
    # cache the features
    adapter.features
    expect(cache.read("flipper/v1/features")).not_to be(nil)

    adapter.get_all
    expect(cache.read("flipper/v1/get_all")).not_to be(nil)

    # expire cache
    adapter.expire_features_cache
    expect(cache.read("flipper/v1/features")).to be(nil)
    expect(cache.read("flipper/v1/get_all")).to be(nil)
  end

  it "can expire feature cache" do
    # cache the features
    adapter.get(flipper[:stats])
    expect(cache.read("flipper/v1/feature/stats")).not_to be(nil)

    adapter.get_all
    expect(cache.read("flipper/v1/get_all")).not_to be(nil)

    # expire cache
    adapter.expire_feature_cache("stats")
    expect(cache.read("flipper/v1/feature/stats")).to be(nil)
    expect(cache.read("flipper/v1/get_all")).to be(nil)
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

    it "knows get_all_cache_key" do
      expect(adapter.get_all_cache_key).to eq("foo/flipper/v1/get_all")
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
      get_all_cache_value = cache.read("foo/flipper/v1/get_all")
      expect(cache.read("foo/flipper/v1/features")).to eq(Set["stats", "search"])
      expect(get_all_cache_value["search"][:percentage_of_actors]).to eq("10")
      expect(get_all_cache_value["stats"][:boolean]).to eq("true")
    end
  end

  describe '#remove' do
    let(:feature) { flipper[:stats] }

    before do
      adapter.get(feature)
      adapter.get_all
      adapter.remove(feature)
    end

    it 'expires feature and deletes the cache' do
      expect(cache.read("flipper/v1/feature/#{feature.key}")).to be_nil
      expect(cache.read("flipper/v1/get_all")).to be(nil)
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
      adapter.get(feature)
      adapter.get_all
      adapter.enable(feature, feature.gate(:boolean), Flipper::Types::Boolean.new(true))
    end

    it 'enables feature and deletes the cache' do
      expect(cache.read("flipper/v1/get_all")).to be(nil)
      expect(cache.read("flipper/v1/feature/#{feature.key}")).to be_nil
      expect(cache.exist?("flipper/v1/feature/#{feature.key}")).to be(false)
      expect(feature).to be_enabled
    end

    context 'with write-through caching' do
      let(:write_through) { true }

      it 'expires feature and writes to the cache' do
        expect(cache.read("flipper/v1/get_all")).to be(nil)
        expect(cache.exist?("flipper/v1/feature/#{feature.key}")).to be(true)
        expect(cache.read("flipper/v1/feature/#{feature.key}")).to include(boolean: 'true')
        expect(feature).to be_enabled
      end
    end
  end

  describe '#disable' do
    let(:feature) { flipper[:stats] }

    before do
      adapter.get(feature)
      adapter.get_all
      adapter.disable(feature, feature.gate(:boolean), Flipper::Types::Boolean.new)
    end

    it 'disables feature and deletes the cache' do
      expect(cache.read("flipper/v1/get_all")).to be(nil)
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
      get_all_cache_value = cache.read("flipper/v1/get_all")
      expect(get_all_cache_value).not_to be(nil)
      expect(get_all_cache_value["stats"][:boolean]).to eq('true')
      expect(get_all_cache_value["search"][:boolean]).to be(nil)
      expect(cache.read("flipper/v1/features")).to eq(Set["stats", "search"])
    end

    it 'returns same result when already cached' do
      expect(adapter.get_all).to eq(adapter.get_all)
    end

    it 'only invokes two calls to wrapped adapter (for features set and gate data for each feature in set)' do
      memory_adapter.reset
      5.times { adapter.get_all }
      expect(memory_adapter.count(:get_all)).to eq(1)
      expect(memory_adapter.count).to eq(1)
    end
  end

  describe '#import' do
    it "delegates to the wrapped adapter's import" do
      source = Flipper::Adapters::Memory.new
      result = Object.new
      expect(memory_adapter).to receive(:import).with(source).and_return(result)

      expect(adapter.import(source)).to be(result)
    end

    it 'expires caches for changed, added, and removed features' do
      flipper[:changed].add
      flipper[:removed].enable

      source_adapter = Flipper::Adapters::Memory.new
      source_flipper = Flipper.new(source_adapter)
      source_flipper[:changed].enable
      source_flipper[:added].enable

      [:changed, :added, :removed].each { |key| adapter.get(flipper[key]) }
      adapter.features
      adapter.get_all

      expect(adapter.import(source_adapter)).to be(true)
      expect(cache.read('flipper/v1/feature/changed')).to be_nil
      expect(cache.read('flipper/v1/feature/added')).to be_nil
      expect(cache.read('flipper/v1/feature/removed')).to be_nil
      expect(cache.read('flipper/v1/features')).to be_nil
      expect(cache.read('flipper/v1/get_all')).to be_nil
      expect(flipper[:changed]).to be_enabled
      expect(flipper[:added]).to be_enabled
      expect(flipper[:removed]).not_to be_enabled
    end

    it 'preserves import errors without expiring caches' do
      flipper[:existing].enable
      adapter.get(flipper[:existing])
      adapter.features
      adapter.get_all

      cached_feature = cache.read('flipper/v1/feature/existing')
      cached_features = cache.read('flipper/v1/features')
      cached_get_all = cache.read('flipper/v1/get_all')
      error = Class.new(StandardError).new('import failed')
      allow(memory_adapter).to receive(:import).and_raise(error)
      expect(cache).not_to receive(:delete)

      expect { adapter.import(Flipper::Adapters::Memory.new) }
        .to raise_error { |raised| expect(raised).to be(error) }
      expect(cache.read('flipper/v1/feature/existing')).to eq(cached_feature)
      expect(cache.read('flipper/v1/features')).to eq(cached_features)
      expect(cache.read('flipper/v1/get_all')).to eq(cached_get_all)
    end

    it 'does not expire caches when the wrapped adapter declines the import' do
      flipper[:existing].enable
      adapter.get(flipper[:existing])
      allow(memory_adapter).to receive(:import).and_return(false)
      expect(cache).not_to receive(:delete)

      expect(adapter.import(Flipper::Adapters::Memory.new)).to be(false)
      expect(cache.read('flipper/v1/feature/existing')).not_to be_nil
    end
  end

  describe '#name' do
    it 'is active_support_cache_store' do
      expect(subject.name).to be(:active_support_cache_store)
    end
  end
end
