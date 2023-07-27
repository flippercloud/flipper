require 'flipper/adapters/operation_logger'
require 'flipper/adapters/dalli'
require 'logger'

RSpec.describe Flipper::Adapters::Dalli do
  let(:memory_adapter) do
    Flipper::Adapters::OperationLogger.new(Flipper::Adapters::Memory.new)
  end
  let(:cache)   { Dalli::Client.new(ENV['MEMCACHED_URL']) }
  let(:adapter) { described_class.new(memory_adapter, cache, 10) }
  let(:flipper) { Flipper.new(adapter) }

  subject { adapter }

  before do
    Dalli.logger = Logger.new('/dev/null')
    skip_on_error(Dalli::NetworkError, 'Memcached not available') do
      cache.flush
    end
  end

  it_should_behave_like 'a flipper adapter'

  it "knows ttl" do
    expect(adapter.ttl).to eq(10)
  end

  it "can expire features cache" do
    # cache the features
    adapter.features
    expect(cache.get("flipper/v1/features")).not_to be(nil)

    # expire cache
    adapter.expire_features_cache
    expect(cache.get("flipper/v1/features")).to be(nil)
  end

  it "can expire feature cache" do
    # cache the features
    adapter.get(flipper[:stats])
    expect(cache.get("flipper/v1/feature/stats")).not_to be(nil)

    # expire cache
    adapter.expire_feature_cache("stats")
    expect(cache.get("flipper/v1/feature/stats")).to be(nil)
  end

  it "can generate feature cache key" do
    expect(adapter.feature_cache_key("stats")).to eq("flipper/v1/feature/stats")
  end

  context "when using a prefix" do
    let(:adapter) { described_class.new(memory_adapter, cache, 0, prefix: "foo/") }
    it_should_behave_like 'a flipper adapter'

    it "can generate feature cache key" do
      expect(adapter.feature_cache_key("stats")).to eq("foo/flipper/v1/feature/stats")
    end

    it "uses the prefix for all keys" do
      # check individual feature get cached with prefix
      adapter.get(flipper[:stats])
      expect(cache.get("foo/flipper/v1/feature/stats")).not_to be(nil)

      # check individual feature expired with prefix
      adapter.remove(flipper[:stats])
      expect(cache.get("foo/flipper/v1/feature/stats")).to be(nil)

      # enable some stuff
      flipper.enable_percentage_of_actors(:search, 10)
      flipper.enable(:stats)

      # populate the cache
      adapter.get_all

      # verify cached with prefix
      expect(cache.get("foo/flipper/v1/feature/search")[:percentage_of_actors]).to eq("10")
      expect(cache.get("foo/flipper/v1/feature/stats")[:boolean]).to eq("true")
    end
  end

  describe '#remove' do
    it 'expires feature' do
      feature = flipper[:stats]
      adapter.get(feature)
      adapter.remove(feature)
      expect(cache.get("flipper/v1/#{feature.key}")).to be(nil)
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
      expect(cache.get("flipper/v1/feature/#{search.key}")).to be(nil)
      expect(cache.get("flipper/v1/feature/#{other.key}")).to be(nil)

      adapter.get_multi([stats, search, other])

      expect(cache.get("flipper/v1/feature/#{search.key}")[:boolean]).to eq('true')
      expect(cache.get("flipper/v1/feature/#{other.key}")[:boolean]).to be(nil)

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
      expect(cache.get("flipper/v1/feature/#{stats.key}")[:boolean]).to eq('true')
      expect(cache.get("flipper/v1/feature/#{search.key}")[:boolean]).to be(nil)
      expect(cache.get("flipper/v1/features")).to eq(Set["stats", "search"])
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
    it 'is dalli' do
      expect(subject.name).to be(:dalli)
    end
  end
end
