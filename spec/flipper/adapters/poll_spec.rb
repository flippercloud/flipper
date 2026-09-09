require 'flipper/adapters/poll'
require 'flipper/adapters/dual_write'
require 'flipper/adapters/operation_logger'
require 'flipper/adapters/sync/interval_synchronizer'
require 'flipper/instrumenters/memory'
require 'timeout'

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

  context "when persistence fails during a Cloud refresh" do
    let(:state) { Flipper::Adapters::Sync::IntervalSynchronizer::State.new(synced: true) }
    let(:persistent) { Flipper::Adapters::Memory.new(threadsafe: true) }
    let(:local) { Flipper::Adapters::DualWrite.new(local_adapter, persistent) }
    let(:instrumenter) { Flipper::Instrumenters::Memory.new }
    let(:generation) { Concurrent::AtomicFixnum.new(1) }
    let(:poller) { double("Poller", adapter: remote_adapter, last_synced_at: generation, interval: 10, start: nil) }
    let(:instance) { described_class.new(poller, local, state: state, instrumenter: instrumenter) }
    let(:failure) { StandardError.new("database unavailable") }
    let(:clock) { 100.0 }

    before do
      Flipper.new(local).disable(:search)
      allow(Process).to receive(:clock_gettime).and_call_original
      allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC) { clock }
      allow(persistent).to receive(:enable).and_raise(failure)
    end

    it "serves stale reads and reports the failure without consuming the snapshot" do
      expect(Flipper.new(instance).enabled?(:search)).to be(false)
      expect(state.last_poll_at).to eq(0)
      expect(instrumenter.events_by_name("synchronizer_exception.flipper").size).to eq(1)
    end

    it "shares the retry limit across threads and newer snapshots" do
      expect(persistent).to receive(:enable).once.and_raise(failure)
      expect(Flipper.new(instance).enabled?(:search)).to be(false)
      generation.value = 2
      second = described_class.new(poller, local, state: state)
      allow(self).to receive(:clock).and_return(109.9)

      threads = 8.times.map { Thread.new { Flipper.new(second).enabled?(:search) } }
      expect(threads.map(&:value)).to eq([false] * 8)
    end

    it "retries the same snapshot after the interval without another Cloud fetch" do
      expect(Flipper.new(instance).enabled?(:search)).to be(false)
      allow(persistent).to receive(:enable).and_call_original
      allow(self).to receive(:clock).and_return(110.0)
      expect(poller).not_to receive(:sync)

      expect(Flipper.new(instance).enabled?(:search)).to be(true)
      expect(Flipper.new(persistent).enabled?(:search)).to be(true)
      expect(state.last_poll_at).to eq(1)
      expect(state.last_poll_failed_at).to be_nil
    end

    it "honors a longer interval supplied by the poller" do
      expect(Flipper.new(instance).enabled?(:search)).to be(false)
      allow(poller).to receive(:interval).and_return(30)
      allow(self).to receive(:clock).and_return(110.0)
      expect(persistent).not_to receive(:enable)
      expect(Flipper.new(instance).enabled?(:search)).to be(false)
    end

    it "limits repeated failures to one attempt per interval" do
      expect(persistent).to receive(:enable).exactly(3).times.and_raise(failure)
      [100.0, 109.9, 110.0, 110.1, 119.9, 120.0].each do |time|
        allow(self).to receive(:clock).and_return(time)
        expect(Flipper.new(instance).enabled?(:search)).to be(false)
      end
      expect(state.last_poll_at).to eq(0)
    end

    it "does not retry a pending snapshot superseded by a foreground write" do
      state.poll_started
      expect(Flipper.new(instance).enabled?(:search)).to be(false)
      cloud = Flipper::Adapters::DualWrite.new(instance, Flipper::Adapters::Memory.new, synchronization_state: state)
      Flipper.new(cloud).disable(:search)
      allow(persistent).to receive(:enable).and_call_original
      allow(self).to receive(:clock).and_return(110.0)

      expect(Flipper.new(instance).enabled?(:search)).to be(false)
      expect(Flipper.new(persistent).enabled?(:search)).to be(false)
      expect(state.last_poll_at).to eq(1)
    end

    it "continues failing explicit writes during the retry interval" do
      expect(Flipper.new(instance).enabled?(:search)).to be(false)
      expect { Flipper.new(instance).enable(:search) }.to raise_error(failure)
      expect(Flipper.new(local_adapter).enabled?(:search)).to be(false)
    end

    it "preserves reconciliation errors for standalone Poll adapters" do
      standalone = described_class.new(poller, local)
      expect { standalone.get_all }.to raise_error(failure)
    end
  end

  it "serves memory reads while another adapter applies a poll" do
    Flipper.new(local_adapter).disable(:search)
    poller = double("Poller", adapter: remote_adapter, last_synced_at: Concurrent::AtomicFixnum.new(1))
    allow(poller).to receive(:start)
    state = Flipper::Adapters::Sync::IntervalSynchronizer::State.new(synced: true)
    instance = described_class.new(poller, local_adapter, state: state)

    state.lock.enter
    reading_thread = Thread.new { Flipper.new(instance).enabled?(:search) }

    expect(reading_thread.join(1)).to be(reading_thread)
    expect(reading_thread.value).to be(false)
  ensure
    state&.lock&.exit
  end

  it "applies a local write after an in-progress reconciliation" do
    state = Flipper::Adapters::Sync::IntervalSynchronizer::State.new(synced: true)
    memory = Flipper::Adapters::Memory.new(threadsafe: true)
    persistent = Flipper::Adapters::Memory.new(threadsafe: true)
    Flipper.new(memory).disable(:search)
    Flipper.new(persistent).disable(:search)
    local = Flipper::Adapters::DualWrite.new(memory, persistent)
    poller = double("Poller", adapter: remote_adapter, last_synced_at: Concurrent::AtomicFixnum.new(1))
    allow(poller).to receive(:start)
    state.poll_started
    instance = described_class.new(poller, local, state: state)
    cloud = Flipper::Adapters::DualWrite.new(
      instance,
      Flipper::Adapters::Memory.new(threadsafe: true),
      synchronization_state: state,
    )
    refresh_started = Queue.new
    release_refresh = Queue.new
    allow(remote_adapter).to receive(:get_all).and_wrap_original do |original, *args, **kwargs|
      snapshot = original.call(*args, **kwargs)
      refresh_started << true
      release_refresh.pop
      snapshot
    end

    refresh_thread = Thread.new { Flipper.new(instance).enabled?(:search) }
    Timeout.timeout(1) { refresh_started.pop }
    write_started = Queue.new
    allow(state).to receive(:synchronize_write).and_wrap_original do |original, &block|
      write_started << true
      original.call(&block)
    end
    write_thread = Thread.new { Flipper.new(cloud).disable(:search) }
    Timeout.timeout(1) { write_started.pop }
    Timeout.timeout(1) do
      loop do
        break if write_thread.status == "sleep"
        raise "write completed before reconciliation released" unless write_thread.alive?
        Thread.pass
      end
    end
    release_refresh << true
    expect(refresh_thread.join(1)).to be(refresh_thread)
    expect(write_thread.join(1)).to be(write_thread)

    expect(Flipper.new(memory).enabled?(:search)).to be(false)
    expect(Flipper.new(persistent).enabled?(:search)).to be(false)
  ensure
    release_refresh << true if refresh_thread&.alive?
    refresh_thread&.join(1)
    write_thread&.join(1)
  end

  it "does not apply a poll that started before a local write" do
    state = Flipper::Adapters::Sync::IntervalSynchronizer::State.new(synced: true)
    memory = Flipper::Adapters::Memory.new(threadsafe: true)
    persistent = Flipper::Adapters::Memory.new(threadsafe: true)
    remote = Flipper::Adapters::Memory.new(threadsafe: true)
    [memory, persistent, remote].each { |adapter| Flipper.new(adapter).enable(:search) }
    local = Flipper::Adapters::DualWrite.new(memory, persistent)
    poller = Flipper::Poller.new(
      remote_adapter: remote,
      synchronization_state: state,
    )
    allow(poller).to receive(:start)
    poll = described_class.new(poller, local, state: state)
    cloud = Flipper::Adapters::DualWrite.new(poll, remote, synchronization_state: state)
    poll_started = Queue.new
    release_poll = Queue.new
    allow(remote).to receive(:get_all).and_wrap_original do |original, *args, **kwargs|
      snapshot = original.call(*args, **kwargs)
      poll_started << true
      release_poll.pop
      snapshot
    end

    polling_thread = Thread.new { poller.sync }
    Timeout.timeout(1) { poll_started.pop }
    Flipper.new(cloud).disable(:search)
    release_poll << true
    expect(polling_thread.join(1)).to be(polling_thread)

    expect(Flipper.new(cloud).enabled?(:search)).to be(false)
    expect(Flipper.new(persistent).enabled?(:search)).to be(false)
  ensure
    release_poll << true if polling_thread&.alive?
    polling_thread&.join(1)
  end
end
