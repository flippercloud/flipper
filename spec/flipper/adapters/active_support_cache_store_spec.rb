require 'helper'
require 'active_support/cache'
require 'active_support/cache/dalli_store'
require 'flipper/adapters/operation_logger'
require 'flipper/adapters/active_support_cache_store'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::ActiveSupportCacheStore do
  let(:memory_adapter) do
    Flipper::Adapters::OperationLogger.new(Flipper::Adapters::Memory.new)
  end
  let(:cache) { ActiveSupport::Cache::DalliStore.new(ENV['MEMCACHED_URL']) }
  let(:adapter) { described_class.new(memory_adapter, cache, expires_in: 10.seconds) }
  let(:flipper) { Flipper.new(adapter) }

  subject { adapter }

  before do
    cache.clear
  end

  it_should_behave_like 'a flipper adapter'

  describe '#remove' do
    it 'expires feature' do
      feature = flipper[:stats]
      adapter.get(feature)
      adapter.remove(feature)
      expect(cache.read(described_class.key_for(feature))).to be(nil)
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
      expect(cache.read(described_class.key_for(search))).to be(nil)
      expect(cache.read(described_class.key_for(other))).to be(nil)

      adapter.get_multi([stats, search, other])

      expect(cache.read(described_class.key_for(search))[:boolean]).to eq('true')
      expect(cache.read(described_class.key_for(other))[:boolean]).to be(nil)

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
      expect(cache.read(described_class.key_for(stats))[:boolean]).to eq('true')
      expect(cache.read(described_class.key_for(search))[:boolean]).to be(nil)
      expect(cache.read(described_class::GetAllKey)).to be_within(2).of(Time.now.to_i)
    end

    it 'returns same result when already cached' do
      expect(adapter.get_all).to eq(adapter.get_all)
    end

    it 'only invokes one call to wrapped adapter' do
      memory_adapter.reset
      5.times { adapter.get_all }
      expect(memory_adapter.count(:get_all)).to eq(1)
    end
  end

  describe '#name' do
    it 'is active_support_cache_store' do
      expect(subject.name).to be(:active_support_cache_store)
    end
  end
end
