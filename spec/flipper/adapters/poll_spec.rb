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

  describe '#read_integer / #set_integer_if_greater' do
    it 'forwards through the synced local adapter' do
      instance = described_class.new(poller, local_adapter)
      expect(instance.set_integer_if_greater(:sync_version, 42)).to eq(true)
      expect(instance.read_integer(:sync_version)).to eq(42)
      expect(local_adapter.read_integer(:sync_version)).to eq(42)
    end
  end
end
