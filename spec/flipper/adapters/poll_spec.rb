require 'flipper/adapters/poll'

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

  it "installs the exact upstream pair without relabeling mutable poller memory" do
    snapshot = Flipper::Snapshot.new(features: remote_adapter.get_all, version: 20)
    allow(remote_adapter).to receive(:get_all_snapshot).and_return(snapshot)
    allow(poller).to receive(:start)
    instance = described_class.new(poller, local_adapter)
    poller.adapter.clear(Flipper::Feature.new(:search, poller.adapter))

    expect(instance.get(Flipper::Feature.new(:search, instance))[:boolean]).to eq('true')
    expect(local_adapter.apply_snapshot(Flipper::Snapshot.new(features: {}, version: 19))).to eq(:stale)
    expect(local_adapter.features).to include('search')
    expect(instance.get_all_snapshot.version).to be_nil
  end
end
