require 'helper'
require 'flipper/adapters/memory'
require 'flipper/adapters/dalli'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::Dalli do
  let(:memory_adapter) { Flipper::Adapters::Memory.new }
  let(:adapter) { described_class.new(memory_adapter, DataStores.dalli) }
  let(:flipper) { Flipper.new(adapter) }

  subject { described_class.new(adapter, DataStores.dalli) }

  before do
    DataStores.reset_dalli
  end

  it_should_behave_like 'a flipper adapter'

  describe '#remove' do
    it 'expires feature' do
      feature = flipper[:stats]
      adapter.get(feature)
      adapter.remove(feature)
      expect(DataStores.dalli.get(described_class.key_for(feature))).to be(nil)
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
      expect(DataStores.dalli.get(described_class.key_for(search))).to be(nil)
      expect(DataStores.dalli.get(described_class.key_for(other))).to be(nil)

      adapter.get_multi([stats, search, other])

      expect(DataStores.dalli.get(described_class.key_for(search))[:boolean]).to eq('true')
      expect(DataStores.dalli.get(described_class.key_for(other))[:boolean]).to be(nil)
    end
  end

  describe '#name' do
    it 'is dalli' do
      expect(subject.name).to be(:dalli)
    end
  end
end
