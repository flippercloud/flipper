require 'helper'
require 'active_support/cache'
require 'flipper/adapters/memory'
require 'flipper/adapters/cache_store'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::CacheStore do
  let(:memory_adapter) { Flipper::Adapters::Memory.new }
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:adapter) { described_class.new(memory_adapter, cache) }
  let(:flipper) { Flipper.new(adapter) }

  subject { adapter }

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

      adapter.get(stats)
      expect(cache.read(described_class.key_for(search))).to be(nil)
      expect(cache.read(described_class.key_for(other))).to be(nil)

      adapter.get_multi([stats, search, other])

      expect(cache.read(described_class.key_for(search))[:boolean]).to eq('true')
      expect(cache.read(described_class.key_for(other))[:boolean]).to be(nil)
    end
  end

  describe '#name' do
    it 'is cache_store' do
      expect(subject.name).to be(:cache_store)
    end
  end
end
