require 'helper'
require 'flipper/adapters/operation_logger'
require 'flipper/adapters/dalli'
require 'flipper/spec/shared_adapter_specs'
require 'logger'

RSpec.describe Flipper::Adapters::Dalli do
  let(:memory_adapter) do
    Flipper::Adapters::OperationLogger.new(Flipper::Adapters::Memory.new)
  end
  let(:cache)   { Dalli::Client.new(ENV['MEMCACHED_URL']) }
  let(:adapter) { described_class.new(memory_adapter, cache) }
  let(:flipper) { Flipper.new(adapter) }

  subject { adapter }

  before do
    Dalli.logger = Logger.new('/dev/null')
    begin
      cache.flush
    rescue Dalli::NetworkError
      skip "Memcached not available"
    end
  end

  it_should_behave_like 'a flipper adapter'

  describe '#remove' do
    it 'expires feature' do
      feature = flipper[:stats]
      adapter.get(feature)
      adapter.remove(feature)
      expect(cache.get(described_class.key_for(feature))).to be(nil)
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
      expect(cache.get(described_class.key_for(search))).to be(nil)
      expect(cache.get(described_class.key_for(other))).to be(nil)

      adapter.get_multi([stats, search, other])

      expect(cache.get(described_class.key_for(search))[:boolean]).to eq('true')
      expect(cache.get(described_class.key_for(other))[:boolean]).to be(nil)

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
      expect(cache.get(described_class.key_for(stats))[:boolean]).to eq('true')
      expect(cache.get(described_class.key_for(search))[:boolean]).to be(nil)
      expect(cache.get(described_class::GetAllKey)).to be_within(2).of(Time.now.to_i)
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
    it 'is dalli' do
      expect(subject.name).to be(:dalli)
    end
  end
end
