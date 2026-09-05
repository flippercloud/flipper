require 'flipper/adapters/poll'
require 'flipper/adapters/operation_logger'
require 'flipper/adapters/sync/interval_synchronizer'

RSpec.describe Flipper::Adapters::Poll do
  let(:remote_adapter) {
    adapter = Flipper::Adapters::Memory.new(threadsafe: true)
    flipper = Flipper.new(adapter)
    flipper.enable(:search)
    flipper.enable(:analytics)
    adapter
  }
  let(:local_adapter) { Flipper::Adapters::Memory.new(threadsafe: true) }
  let(:poller) {
    Flipper::Poller.get("for_spec", {
      start_automatically: false,
      remote_adapter: remote_adapter,
    })
  }

  it "syncs in main thread if local adapter is empty" do
    instance = described_class.new(poller, local_adapter)
    instance.features # call something to force sync
    expect(local_adapter.features).to eq(remote_adapter.features)
  end

  it "does not sync in main thread if local adapter is not empty" do
    # make local not empty by importing remote
    flipper = Flipper.new(local_adapter)
    flipper.import(remote_adapter)

    # make a fake poller to verify calls
    poller = double("Poller", last_synced_at: Concurrent::AtomicFixnum.new(0))
    expect(poller).to receive(:start).twice
    expect(poller).not_to receive(:sync)

    # create new instance and call something to force sync
    instance = described_class.new(poller, local_adapter)
    instance.features # call something to force sync

    expect(local_adapter.features).to eq(remote_adapter.features)
  end

  it "coordinates synchronization across adapters that share state" do
    memory = Flipper::Adapters::Memory.new(threadsafe: true)
    Flipper.new(memory).disable(:search)
    local = Flipper::Adapters::OperationLogger.new(memory)
    timestamp = Concurrent::AtomicFixnum.new(1)
    poller = double("Poller", adapter: remote_adapter, last_synced_at: timestamp)
    allow(poller).to receive(:start)
    state = Flipper::Adapters::Sync::IntervalSynchronizer::State.new(synced: true)
    first = described_class.new(poller, local, state: state)
    second = described_class.new(poller, local, state: state)
    local.reset

    expect(Flipper.new(first).enabled?(:search)).to be(true)
    expect(Flipper.new(second).enabled?(:search)).to be(true)
    expect(local.count(:get_all)).to be(1)
  end

  it "serves memory reads while another adapter applies a poll" do
    Flipper.new(local_adapter).disable(:search)
    poller = double("Poller", adapter: remote_adapter, last_synced_at: Concurrent::AtomicFixnum.new(1))
    allow(poller).to receive(:start)
    state = Flipper::Adapters::Sync::IntervalSynchronizer::State.new(synced: true)
    instance = described_class.new(poller, local_adapter, state: state)

    state.lock.enter
    reading_thread = Thread.new { Flipper.new(instance).enabled?(:search) }

    expect(reading_thread.value).to be(false)
  ensure
    state&.lock&.exit
  end
end
