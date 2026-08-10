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

  it "only synchronizes once per poller update when called concurrently" do
    flipper = Flipper.new(local_adapter)
    flipper.enable(:existing)

    get_all_calls = Concurrent::AtomicFixnum.new(0)
    slow_remote_adapter = Class.new do
      def initialize(result, get_all_calls)
        @result = result
        @get_all_calls = get_all_calls
      end

      def get_all(**kwargs)
        @get_all_calls.increment
        sleep 0.05
        @result
      end
    end.new(local_adapter.get_all, get_all_calls)

    fake_poller = Struct.new(:last_synced_at, :adapter) do
      def start
      end

      def sync
        raise "sync should not be called when the local adapter is not empty"
      end
    end.new(Concurrent::AtomicFixnum.new(1), slow_remote_adapter)

    instance = described_class.new(fake_poller, local_adapter)
    threads = 10.times.map { Thread.new { instance.features } }
    threads.each(&:join)

    expect(get_all_calls.value).to eq(1)
  end

  it "does not wait for an in-flight poller update before returning the adapter" do
    flipper = Flipper.new(local_adapter)
    flipper.enable(:existing)

    remote = Flipper::Adapters::Memory.new(threadsafe: true)
    Flipper.new(remote).enable(:updated)

    entered = Queue.new
    release = Queue.new
    slow_remote_adapter = Class.new do
      def initialize(result, entered, release)
        @result = result
        @entered = entered
        @release = release
      end

      def get_all(**kwargs)
        @entered << true
        @release.pop
        @result
      end
    end.new(remote.get_all, entered, release)

    fake_poller = Struct.new(:last_synced_at, :adapter) do
      def start
      end

      def sync
        raise "sync should not be called when the local adapter is not empty"
      end
    end.new(Concurrent::AtomicFixnum.new(1), slow_remote_adapter)

    instance = described_class.new(fake_poller, local_adapter)
    first_thread = Thread.new { instance.features }
    entered.pop

    completed = Queue.new
    second_thread = Thread.new { completed << instance.features }
    second_thread.join(1)

    # The second thread serves the local adapter as is rather than blocking on
    # the sync the first thread is running.
    expect(completed.pop(true)).to eq(Set["existing"])

    release << true
    expect(first_thread.value).to eq(Set["updated"])
  end

  it "serves a coherent snapshot while a poller update is being applied" do
    entered = Queue.new
    release = Queue.new
    pausing_local_adapter = Class.new(Flipper::Adapters::Memory) do
      def initialize(entered, release)
        super(nil, threadsafe: true)
        @entered = entered
        @release = release
        @pause = true
      end

      def disable(feature, gate, thing)
        result = super
        if @pause
          @pause = false
          @entered << true
          @release.pop
        end
        result
      end
    end.new(entered, release)
    Flipper.new(pausing_local_adapter).enable(:existing)

    remote = Flipper::Adapters::Memory.new(threadsafe: true)
    Flipper.new(remote).disable(:existing)
    Flipper.new(remote).enable(:updated)

    fake_poller = Struct.new(:last_synced_at, :adapter) do
      def start
      end

      def sync
        raise "sync should not be called when the local adapter is not empty"
      end
    end.new(Concurrent::AtomicFixnum.new(1), remote)

    instance = described_class.new(fake_poller, pausing_local_adapter)
    first_thread = Thread.new { instance.features }
    entered.pop

    expect(Flipper.new(pausing_local_adapter).enabled?(:existing)).to be(false)
    expect(Flipper.new(instance).enabled?(:existing)).to be(true)

    release << true
    expect(first_thread.value).to eq(Set["existing", "updated"])
    expect(Flipper.new(instance).enabled?(:existing)).to be(false)
  end

  it "keeps the claimed snapshot after the poller update completes" do
    flipper = Flipper.new(local_adapter)
    flipper.enable(:existing)

    remote = Flipper::Adapters::Memory.new(threadsafe: true)
    Flipper.new(remote).enable(:updated)

    sync_entered = Queue.new
    release_sync = Queue.new
    slow_remote_adapter = Class.new do
      def initialize(result, entered, release)
        @result = result
        @entered = entered
        @release = release
      end

      def get_all(**kwargs)
        @entered << true
        @release.pop
        @result
      end
    end.new(remote.get_all, sync_entered, release_sync)

    fake_poller = Struct.new(:last_synced_at, :adapter) do
      def start
      end

      def sync
        raise "sync should not be called when the local adapter is not empty"
      end
    end.new(Concurrent::AtomicFixnum.new(1), slow_remote_adapter)

    instance = described_class.new(fake_poller, local_adapter)
    loser_claimed = Queue.new
    release_loser = Queue.new
    allow(instance).to receive(:claim_sync).and_wrap_original do |method, *args|
      result = method.call(*args)
      if Thread.current[:poll_loser]
        loser_claimed << true
        release_loser.pop
      end
      result
    end

    winner = Thread.new { instance.features }
    sync_entered.pop
    loser = Thread.new do
      Thread.current[:poll_loser] = true
      instance.features
    end
    loser_claimed.pop

    release_sync << true
    expect(winner.value).to eq(Set["updated"])
    release_loser << true

    expect(loser.value).to eq(Set["existing"])
  ensure
    release_sync << true if release_sync
    release_loser << true if release_loser
    winner&.join
    loser&.join
  end

  it "keeps a coherent snapshot when the sync claim mutex is contended" do
    get_all_entered = Queue.new
    release_get_all = Queue.new
    pausing_local_adapter = Class.new(Flipper::Adapters::Memory) do
      def initialize(entered, release)
        super(nil, threadsafe: true)
        @entered = entered
        @release = release
        @pause_next_get_all = false
      end

      def pause_next_get_all
        @pause_next_get_all = true
      end

      def get_all(**kwargs)
        if @pause_next_get_all
          @pause_next_get_all = false
          @entered << true
          @release.pop
        end
        super
      end
    end.new(get_all_entered, release_get_all)
    Flipper.new(pausing_local_adapter).enable(:existing)

    remote = Flipper::Adapters::Memory.new(threadsafe: true)
    Flipper.new(remote).enable(:updated)
    fake_poller = Struct.new(:last_synced_at, :adapter) do
      def start
      end

      def sync
        raise "sync should not be called when the local adapter is not empty"
      end
    end.new(Concurrent::AtomicFixnum.new(1), remote)

    instance = described_class.new(fake_poller, pausing_local_adapter)
    pausing_local_adapter.pause_next_get_all

    loser_claimed = Queue.new
    release_loser = Queue.new
    allow(instance).to receive(:claim_sync).and_wrap_original do |method, *args|
      result = method.call(*args)
      if Thread.current[:poll_contender]
        loser_claimed << true
        release_loser.pop
      end
      result
    end

    winner = Thread.new { instance.features }
    get_all_entered.pop
    loser = Thread.new do
      Thread.current[:poll_contender] = true
      instance.features
    end
    loser_claimed.pop

    release_get_all << true
    expect(winner.value).to eq(Set["updated"])
    release_loser << true

    expect(loser.value).to eq(Set["existing"])
  ensure
    release_get_all << true if release_get_all
    release_loser << true if release_loser
    winner&.join
    loser&.join
  end

  it "reads the local adapter once for a claimed poller update" do
    Flipper.new(local_adapter).enable(:existing)

    fake_poller = Struct.new(:last_synced_at, :adapter) do
      def start
      end

      def sync
        raise "sync should not be called when the local adapter is not empty"
      end
    end.new(Concurrent::AtomicFixnum.new(1), remote_adapter)

    instance = described_class.new(fake_poller, local_adapter)
    expect(local_adapter).to receive(:get_all).once.and_call_original

    instance.features
  end

  it "does not wait for the sync claim mutex" do
    Flipper.new(local_adapter).enable(:existing)

    fake_poller = Struct.new(:last_synced_at, :adapter) do
      def start
      end

      def sync
        raise "sync should not be called when the local adapter is not empty"
      end
    end.new(Concurrent::AtomicFixnum.new(1), remote_adapter)

    instance = described_class.new(fake_poller, local_adapter)
    state = instance.instance_variable_get(:@sync_state).get
    locked = Queue.new
    release = Queue.new
    holder = Thread.new do
      state.mutex.lock
      locked << true
      release.pop
      state.mutex.unlock
    end
    locked.pop

    completed = Queue.new
    caller = Thread.new { completed << instance.features }
    caller.join(1)

    expect(completed.pop(true)).to eq(Set["existing"])
  ensure
    release << true if release
    holder&.join
    caller&.join
  end

  it "retries a poller update after synchronization fails" do
    flipper = Flipper.new(local_adapter)
    flipper.enable(:existing)

    get_all_calls = Concurrent::AtomicFixnum.new(0)
    flaky_remote_adapter = Class.new do
      def initialize(result, get_all_calls)
        @result = result
        @get_all_calls = get_all_calls
      end

      def get_all(**kwargs)
        raise "transient failure" if @get_all_calls.increment == 1

        @result
      end
    end.new(local_adapter.get_all, get_all_calls)

    fake_poller = Struct.new(:last_synced_at, :adapter) do
      def start
      end

      def sync
        raise "sync should not be called when the local adapter is not empty"
      end
    end.new(Concurrent::AtomicFixnum.new(1), flaky_remote_adapter)

    instance = described_class.new(fake_poller, local_adapter)

    expect { instance.features }.to raise_error("transient failure")
    instance.features

    expect(get_all_calls.value).to eq(2)
  end

  it "resets in-flight synchronization state after a fork" do
    flipper = Flipper.new(local_adapter)
    flipper.enable(:existing)

    remote = Flipper::Adapters::Memory.new(threadsafe: true)
    Flipper.new(remote).enable(:updated)

    get_all_calls = Concurrent::AtomicFixnum.new(0)
    counting_remote_adapter = Class.new do
      def initialize(result, get_all_calls)
        @result = result
        @get_all_calls = get_all_calls
      end

      def get_all(**kwargs)
        @get_all_calls.increment
        @result
      end
    end.new(remote.get_all, get_all_calls)

    fake_poller = Struct.new(:last_synced_at, :adapter) do
      def start
      end

      def sync
        raise "sync should not be called when the local adapter is not empty"
      end
    end.new(Concurrent::AtomicFixnum.new(1), counting_remote_adapter)

    instance = described_class.new(fake_poller, local_adapter)
    stale_state = instance.instance_variable_get(:@sync_state).get
    stale_state.syncing = true

    allow(Process).to receive(:pid).and_return(stale_state.pid + 1)

    threads = 10.times.map { Thread.new { instance.features } }
    expect(threads.map(&:value)).to all(eq(Set["updated"]))
    expect(get_all_calls.value).to eq(1)
  end
end
