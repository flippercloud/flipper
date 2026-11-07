require 'active_support'
require 'active_support/cache'
require 'flipper/adapters/active_support_cache_store'
require 'flipper/adapters/dual_write'
require 'flipper/adapters/failover'
require 'flipper/adapters/failsafe'
require 'flipper/adapters/instrumented'
require 'flipper/adapters/operation_logger'
require 'flipper/adapters/read_only'
require 'flipper/adapters/sync'
require 'flipper/instrumenters/memory'

RSpec.describe 'Snapshot wrapper contracts' do
  let(:memory) { Flipper::Adapters::Memory.new }
  let(:source) do
    adapter = Flipper::Adapters::Memory.new
    Flipper.new(adapter).enable(:search)
    adapter
  end
  let(:snapshot) { Flipper::Snapshot.new(features: source.get_all, version: 10) }

  [Flipper::Adapters::Wrapper, Flipper::Adapters::OperationLogger,
   Flipper::Adapters::Instrumented, Flipper::Adapters::Memoizable].each do |wrapper_class|
    context wrapper_class.name do
      subject(:wrapper) { wrapper_class.new(memory) }

      it 'delegates capability, installation and stale rejection' do
        expect(wrapper.supports?(:atomic_snapshot_install)).to eq(true)
        expect(wrapper.apply_snapshot(snapshot)).to eq(:applied)
        expect(memory.get_all).to eq(snapshot.features)
        expect(wrapper.apply_snapshot(Flipper::Snapshot.new(features: {}, version: 9))).to eq(:stale)
        expect(memory.get_all).to eq(snapshot.features)
      end

      it 'forwards the exact source snapshot and keyword arguments' do
        expect(memory).to receive(:get_all_snapshot).with(cache_bust: true).and_return(snapshot)
        expect(wrapper.get_all_snapshot(cache_bust: true)).to equal(snapshot)
      end

      it 'does not turn installation failure into success' do
        expect(memory).to receive(:apply_snapshot).with(snapshot).and_raise('install failed')
        expect { wrapper.apply_snapshot(snapshot) }.to raise_error('install failed')
      end

      it 'forwards the feature instrumenter to the native installer' do
        instrumenter = Flipper::Instrumenters::Memory.new
        expect(memory).to receive(:apply_snapshot).with(snapshot, instrumenter: instrumenter).and_return(:unchanged)
        expect(wrapper.apply_snapshot(snapshot, instrumenter: instrumenter)).to eq(:unchanged)
      end
    end
  end

  it 'clears memoized feature and collection reads after an install' do
    wrapper = Flipper::Adapters::Memoizable.new(memory)
    wrapper.memoize = true
    feature = Flipper::Feature.new(:search, wrapper)
    expect(wrapper.get(feature)[:boolean]).to be_nil
    expect(wrapper.features).to be_empty
    wrapper.get_all

    wrapper.apply_snapshot(snapshot)

    expect(wrapper.get(feature)[:boolean]).to eq('true')
    expect(wrapper.features).to eq(Set['search'])
    expect(wrapper.get_all).to eq(snapshot.features)
  end

  it 'instruments the install outcome' do
    instrumenter = Flipper::Instrumenters::Memory.new
    wrapper = Flipper::Adapters::Instrumented.new(memory, instrumenter: instrumenter)
    wrapper.apply_snapshot(snapshot)
    expect(instrumenter.events.last.payload).to include(operation: :apply_snapshot, result: :applied)
  end

  it 'does not advertise or allow writes through ReadOnly' do
    wrapper = Flipper::Adapters::ReadOnly.new(memory)
    expect(wrapper.supports?(:atomic_snapshot_install)).to eq(false)
    expect { wrapper.apply_snapshot(snapshot) }.to raise_error(Flipper::Adapters::ReadOnly::WriteAttempted)
    expect(memory.get_all).to eq({})
  end

  it 'keeps multi-store and failsafe wrappers on released synchronization behavior' do
    wrappers = [
      Flipper::Adapters::DualWrite.new(memory, source),
      Flipper::Adapters::Failover.new(memory, source, dual_write: true),
      Flipper::Adapters::Failsafe.new(memory),
      Flipper::Adapters::Sync.new(memory, source),
      Flipper::Adapters::ActiveSupportCacheStore.new(memory, ActiveSupport::Cache::MemoryStore.new),
    ]
    wrappers.each do |wrapper|
      expect(wrapper.supports?(:atomic_snapshot_install)).to eq(false)
      expect { wrapper.apply_snapshot(snapshot) }.to raise_error(NotImplementedError)
    end
  end

  it 'preserves the paired snapshot through Sync after synchronizing' do
    synchronizer = double('synchronizer', call: nil)
    wrapper = Flipper::Adapters::Sync.new(memory, source, synchronizer: synchronizer)
    expect(synchronizer).to receive(:call).ordered
    expect(memory).to receive(:get_all_snapshot).with(cache_bust: true).ordered.and_return(snapshot)
    expect(wrapper.get_all_snapshot(cache_bust: true)).to equal(snapshot)
  end

  it 'uses one failover source for both data and version' do
    wrapper = Flipper::Adapters::Failover.new(memory, source)
    expect(memory).to receive(:get_all_snapshot).with(cache_bust: true).and_raise('unavailable')
    expect(source).to receive(:get_all_snapshot).with(cache_bust: true).and_return(snapshot)
    expect(wrapper.get_all_snapshot(cache_bust: true)).to equal(snapshot)
  end

  it 'returns an unversioned empty snapshot on a failsafe read failure' do
    wrapper = Flipper::Adapters::Failsafe.new(memory)
    expect(memory).to receive(:get_all_snapshot).and_raise('unavailable')
    result = wrapper.get_all_snapshot
    expect(result.features).to eq({})
    expect(result.version).to be_nil
  end

  it 'does not reconstruct a snapshot from cached independent reads' do
    wrapper = Flipper::Adapters::ActiveSupportCacheStore.new(memory, ActiveSupport::Cache::MemoryStore.new)
    wrapper.get_all
    expect(memory).to receive(:get_all_snapshot).with(cache_bust: true).and_return(snapshot)
    expect(wrapper.get_all_snapshot(cache_bust: true)).to equal(snapshot)
  end
end
