require "flipper/adapters/poll"
require "flipper/adapters/dual_write"
require "flipper/adapters/sync/interval_synchronizer"

RSpec.describe "Cloud polling partial failures" do
  let(:memory) { Flipper::Adapters::Memory.new(threadsafe: true) }
  let(:persistent) { Flipper::Adapters::Memory.new(threadsafe: true) }
  let(:remote) { Flipper::Adapters::Memory.new(threadsafe: true) }
  let(:state) { Flipper::Adapters::Sync::IntervalSynchronizer::State.new(synced: true) }
  let(:local) { Flipper::Adapters::DualWrite.new(memory, persistent) }
  let(:poller) { Flipper::Poller.new(remote_adapter: remote, synchronization_state: state) }
  let(:poll) { Flipper::Adapters::Poll.new(poller, local, state: state) }
  let(:cloud) { Flipper.new(Flipper::Adapters::DualWrite.new(poll, remote, synchronization_state: state)) }
  let(:failure) { StandardError.new("injected local failure") }

  before do
    [memory, persistent, remote].each do |adapter|
      Flipper.new(adapter).disable(:first)
      Flipper.new(adapter).disable(:second)
    end
    allow(poller).to receive(:start)
    allow(Process).to receive(:clock_gettime).and_call_original
    allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC).and_return(100.0)
    Flipper.new(remote).enable(:first)
    Flipper.new(remote).enable(:second)
    poller.sync
  end

  def next_interval
    allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC).and_return(110.0)
    # No new snapshot may be fetched during recovery.
    allow(remote).to receive(:get_all).and_raise("Cloud unavailable")
  end

  [false, true].each do |after_commit|
    it "recovers a multi-feature refresh failing #{after_commit ? 'after' : 'before'} persistence commits" do
      allow(persistent).to receive(:enable).and_wrap_original do |original, feature, *args|
        if feature.key == "second"
          original.call(feature, *args) if after_commit
          raise failure
        end
        original.call(feature, *args)
      end

      expect(cloud.enabled?(:first)).to be(true)
      expect(cloud.enabled?(:second)).to be(false)
      expect(state.last_poll_at).to eq(0)
      allow(persistent).to receive(:enable).and_call_original
      next_interval

      expect(cloud.enabled?(:second)).to be(true)
      expect(memory.get_all).to eq(persistent.get_all)
      expect(state.last_poll_at).to eq(poller.last_synced_at.value)
    end
  end

  it "recovers a refresh interrupted while removing a feature" do
    Flipper.new(remote).remove(:second)
    poller.sync
    allow(persistent).to receive(:remove).and_raise(failure)
    expect(cloud.enabled?(:first)).to be(true)
    expect(memory.features).to include("second")
    allow(persistent).to receive(:remove).and_call_original
    next_interval

    expect(cloud.features.map(&:key)).not_to include("second")
    expect(memory.get_all).to eq(persistent.get_all)
  end

  it "waits for a fresh poll after an explicit write fails at Cloud" do
    allow(persistent).to receive(:enable).and_raise(failure)
    expect(cloud.enabled?(:first)).to be(false)
    allow(remote).to receive(:add).and_raise(failure)
    expect { cloud.add(:unrelated) }.to raise_error(failure)
    allow(persistent).to receive(:enable).and_call_original
    next_interval

    expect(cloud.enabled?(:first)).to be(false)
    expect(cloud.enabled?(:second)).to be(false)
    allow(remote).to receive(:get_all).and_call_original
    poller.sync
    expect(cloud.enabled?(:first)).to be(true)
    expect(cloud.enabled?(:second)).to be(true)
    expect(memory.get_all).to eq(persistent.get_all)
  end

  it "waits for a fresh poll after an explicit write fails at persistence" do
    allow(persistent).to receive(:enable).and_raise(failure)
    expect(cloud.enabled?(:first)).to be(false)
    allow(persistent).to receive(:add).and_raise(failure)
    expect { cloud.add(:unrelated) }.to raise_error(failure)
    allow(persistent).to receive(:add).and_call_original
    allow(persistent).to receive(:enable).and_call_original
    next_interval

    expect(cloud.enabled?(:first)).to be(false)
    expect(cloud.enabled?(:second)).to be(false)
    allow(remote).to receive(:get_all).and_call_original
    poller.sync
    expect(cloud.enabled?(:first)).to be(true)
    expect(cloud.enabled?(:second)).to be(true)
    expect(memory.get_all).to eq(persistent.get_all)
  end

  it "converges after a failed explicit write once a new Cloud poll succeeds" do
    allow(persistent).to receive(:enable).and_raise(failure)
    expect(cloud.enabled?(:first)).to be(false)
    allow(remote).to receive(:add).and_raise(failure)
    expect { cloud.add(:unrelated) }.to raise_error(failure)
    allow(persistent).to receive(:enable).and_call_original
    allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC).and_return(110.0)
    poller.sync

    expect(cloud.enabled?(:first)).to be(true)
    expect(cloud.enabled?(:second)).to be(true)
    expect(memory.get_all).to eq(persistent.get_all)
  end
end
