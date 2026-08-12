require 'flipper/adapters/poll'
require 'open3'
require 'rbconfig'

RSpec.describe Flipper::Adapters::Poll do
  FakePoller = Struct.new(:last_synced_at, :adapter) do
    def start
    end

    def sync
      raise "sync should not be called when the local adapter is not empty"
    end
  end

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

  def build_poller(adapter)
    FakePoller.new(Concurrent::AtomicFixnum.new(1), adapter)
  end

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

  it "establishes a snapshot after a local get_all initialization failure" do
    flaky_local_adapter = Class.new(Flipper::Adapters::Memory) do
      def initialize
        super
        @get_all_calls = 0
      end

      def get_all(**kwargs)
        @get_all_calls += 1
        raise "transient local failure" if @get_all_calls == 1

        super
      end
    end.new
    Flipper.new(flaky_local_adapter).enable(:existing)

    fake_poller = build_poller(remote_adapter)

    instance = nil
    expect { instance = described_class.new(fake_poller, flaky_local_adapter) }.not_to raise_error

    expect(instance.features).to eq(Set["existing"])
    expect(instance.features).to eq(Set["analytics", "search"])
  end

  it "serves the established snapshot when initialization recovery races with a sync" do
    flaky_local_adapter = Class.new(Flipper::Adapters::Memory) do
      def initialize
        super
        @get_all_calls = 0
      end

      def get_all(**kwargs)
        @get_all_calls += 1
        raise "transient local failure" if @get_all_calls == 1

        super
      end
    end.new
    Flipper.new(flaky_local_adapter).enable(:existing)

    fake_poller = build_poller(remote_adapter)

    instance = described_class.new(fake_poller, flaky_local_adapter)
    snapshot_established = Queue.new
    release_recovery = Queue.new
    allow(instance).to receive(:claim_sync).and_wrap_original do |method, *args|
      result = method.call(*args)
      if Thread.current[:poll_recovery]
        snapshot_established << true
        release_recovery.pop
      end
      result
    end

    recovery = Thread.new do
      Thread.current[:poll_recovery] = true
      instance.features
    end
    snapshot_established.pop

    expect(instance.features).to eq(Set["analytics", "search"])
    release_recovery << true
    expect(recovery.value).to eq(Set["existing"])
  ensure
    release_recovery << true if release_recovery
    recovery&.join
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

    fake_poller = build_poller(slow_remote_adapter)

    instance = described_class.new(fake_poller, local_adapter)
    threads = 10.times.map { Thread.new { instance.features } }
    threads.each(&:join)

    expect(get_all_calls.value).to eq(1)
  end

  it "serves a coherent snapshot without waiting for an in-flight poller update" do
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

    fake_poller = build_poller(slow_remote_adapter)

    instance = described_class.new(fake_poller, local_adapter)
    first_thread = Thread.new { instance.features }
    entered.pop

    completed = Queue.new
    second_thread = Thread.new { completed << instance.features }
    second_thread.join(1)

    # The second thread reads the pre-sync snapshot without waiting for the
    # first thread's sync to finish.
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

    fake_poller = build_poller(remote)

    instance = described_class.new(fake_poller, pausing_local_adapter)
    first_thread = Thread.new { instance.features }
    entered.pop

    expect(Flipper.new(pausing_local_adapter).enabled?(:existing)).to be(false)
    expect(Flipper.new(instance).enabled?(:existing)).to be(true)

    release << true
    expect(first_thread.value).to eq(Set["existing", "updated"])
    expect(Flipper.new(instance).enabled?(:existing)).to be(false)
  end

  it "keeps mutable gate values isolated in the trusted snapshot" do
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
        if @pause && gate.data_type == :set
          @pause = false
          @entered << true
          @release.pop
        end
        result
      end
    end.new(entered, release)
    actor = Flipper::Actor.new("User;1")
    Flipper.new(pausing_local_adapter).enable_actor(:search, actor)

    remote = Flipper::Adapters::Memory.new(threadsafe: true)
    Flipper.new(remote).enable_percentage_of_actors(:search, 1)
    fake_poller = build_poller(remote)

    instance = described_class.new(fake_poller, pausing_local_adapter)
    winner = Thread.new { instance.features }
    entered.pop

    expect(Flipper.new(pausing_local_adapter).enabled?(:search, actor)).to be(false)
    expect(Flipper.new(instance).enabled?(:search, actor)).to be(true)

    release << true
    expect(winner.value).to eq(Set["search"])
    expect(Flipper.new(instance).enabled?(:search, actor)).to be(false)
  ensure
    release << true if release
    winner&.join
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

    fake_poller = build_poller(slow_remote_adapter)

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
    fake_poller = build_poller(remote)

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

  it "retains the completed snapshot for contention during the next poll" do
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
    Flipper.new(pausing_local_adapter).enable(:original)

    remote = Flipper::Adapters::Memory.new(threadsafe: true)
    Flipper.new(remote).enable(:first_update)
    fake_poller = build_poller(remote)

    instance = described_class.new(fake_poller, pausing_local_adapter)
    expect(instance.features).to eq(Set["first_update"])

    Flipper.new(remote).enable(:second_update)
    fake_poller.last_synced_at.value = 2
    pausing_local_adapter.pause_next_get_all

    winner = Thread.new { instance.features }
    get_all_entered.pop
    contender = Thread.new { instance.features }

    expect(contender.value).to eq(Set["first_update"])
    release_get_all << true
    expect(winner.value).to eq(Set["first_update", "second_update"])
  ensure
    release_get_all << true if release_get_all
    winner&.join
    contender&.join
  end

  it "reads the local adapter before and after a claimed poller update" do
    Flipper.new(local_adapter).enable(:existing)

    fake_poller = build_poller(remote_adapter)

    instance = described_class.new(fake_poller, local_adapter)
    expect(local_adapter).to receive(:get_all).twice.and_call_original

    instance.features
  end

  it "does not fail a successful update when its completed snapshot cannot be captured" do
    flaky_local_adapter = Class.new(Flipper::Adapters::Memory) do
      def initialize
        super
        @get_all_calls = 0
      end

      def get_all(**kwargs)
        @get_all_calls += 1
        raise "completed snapshot failure" if @get_all_calls == 3

        super
      end
    end.new
    Flipper.new(flaky_local_adapter).enable(:existing)

    fake_poller = build_poller(remote_adapter)

    instance = described_class.new(fake_poller, flaky_local_adapter)

    expect { instance.features }.not_to raise_error
    expect(instance.features).to eq(Set["analytics", "search"])
  end

  it "does not wait for the sync claim mutex" do
    Flipper.new(local_adapter).enable(:existing)

    fake_poller = build_poller(remote_adapter)

    instance = described_class.new(fake_poller, local_adapter)
    mutex = instance.instance_variable_get(:@mutex)
    locked = Queue.new
    release = Queue.new
    holder = Thread.new do
      mutex.lock
      locked << true
      release.pop
      mutex.unlock
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

    fake_poller = build_poller(flaky_remote_adapter)

    instance = described_class.new(fake_poller, local_adapter)

    expect { instance.features }.to raise_error("transient failure")
    instance.features

    expect(get_all_calls.value).to eq(2)
  end

  it "retains the last trusted snapshot while retrying a partially failed update" do
    failing_local_adapter = Class.new(Flipper::Adapters::Memory) do
      def initialize
        super(nil, threadsafe: true)
        @fail_next_disable = true
      end

      def disable(feature, gate, thing)
        result = super
        if @fail_next_disable
          @fail_next_disable = false
          raise "partial local failure"
        end
        result
      end
    end.new
    Flipper.new(failing_local_adapter).enable(:existing)

    remote = Flipper::Adapters::Memory.new(threadsafe: true)
    Flipper.new(remote).disable(:existing)
    Flipper.new(remote).enable(:updated)
    retry_entered = Queue.new
    release_retry = Queue.new
    pausing_remote_adapter = Class.new do
      def initialize(result, entered, release)
        @result = result
        @entered = entered
        @release = release
        @get_all_calls = 0
      end

      def get_all(**kwargs)
        @get_all_calls += 1
        if @get_all_calls == 2
          @entered << true
          @release.pop
        end
        @result
      end
    end.new(remote.get_all, retry_entered, release_retry)

    fake_poller = build_poller(pausing_remote_adapter)

    instance = described_class.new(fake_poller, failing_local_adapter)
    expect { instance.features }.to raise_error("partial local failure")
    expect(Flipper.new(failing_local_adapter).enabled?(:existing)).to be(false)

    retrying = Thread.new { instance.features }
    retry_entered.pop

    expect(Flipper.new(instance).enabled?(:existing)).to be(true)
    release_retry << true
    expect(retrying.value).to eq(Set["existing", "updated"])
    expect(Flipper.new(instance).enabled?(:existing)).to be(false)
  ensure
    release_retry << true if release_retry
    retrying&.join
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

    fake_poller = build_poller(counting_remote_adapter)

    instance = described_class.new(fake_poller, local_adapter)
    mutex = instance.instance_variable_get(:@mutex)
    parent_pid = instance.instance_variable_get(:@pid)
    instance.instance_variable_set(:@syncing, true)

    allow(Process).to receive(:pid).and_return(parent_pid + 1)

    threads = 10.times.map { Thread.new { instance.features } }
    expect(threads.map(&:value)).to all(eq(Set["updated"]))
    expect(get_all_calls.value).to eq(1)
    expect(instance.instance_variable_get(:@pid)).to eq(parent_pid + 1)
    expect(instance.instance_variable_get(:@mutex)).to equal(mutex)
  end

  it "keeps its mutex and trusted snapshot in a real forked child" do
    skip "Process.fork is not supported" unless Process.respond_to?(:fork)

    script = <<~'RUBY'
      require "flipper"
      require "flipper/adapters/poll"

      def wait_for(queue, timeout: 2)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
        loop do
          return queue.pop(true)
        rescue ThreadError
          raise "queue wait timed out" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
          Thread.pass
        end
      end

      def join_thread(thread, timeout: 2)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
        until thread.join(0.01)
          raise "thread join timed out" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
        end
      end

      Poller = Struct.new(:last_synced_at, :adapter) do
        def start
        end

        def sync
          raise "unexpected bootstrap sync"
        end
      end

      entered = Queue.new
      release_sync = Queue.new
      remote_calls = 0
      remote = Class.new do
        def initialize(result, entered, release_sync, calls)
          @result = result
          @entered = entered
          @release_sync = release_sync
          @calls = calls
        end

        def get_all(**kwargs)
          @calls[0] += 1
          @entered << true
          @release_sync.pop
          @result
        end
      end

      local_adapter = Flipper::Adapters::Memory.new(threadsafe: true)
      Flipper.new(local_adapter).enable(:existing)
      remote_adapter = Flipper::Adapters::Memory.new(threadsafe: true)
      Flipper.new(remote_adapter).enable(:updated)
      calls = [remote_calls]
      poller = Poller.new(
        Concurrent::AtomicFixnum.new(1),
        remote.new(remote_adapter.get_all, entered, release_sync, calls)
      )
      instance = Flipper::Adapters::Poll.new(poller, local_adapter)
      mutex = instance.instance_variable_get(:@mutex)
      raise "poll does not use a stable Mutex" unless mutex.instance_of?(Mutex)

      Flipper.new(local_adapter).disable(:existing)
      instance.instance_variable_set(:@syncing, true)
      instance.instance_variable_set(:@sync_failed, false)

      mutex_locked = Queue.new
      release_mutex = Queue.new
      holder = Thread.new do
        mutex.lock
        mutex_locked << true
        release_mutex.pop
        mutex.unlock
      end
      wait_for(mutex_locked)

      begin
        child_pid = fork do
          success = false
          winner = nil
          losers = []
          begin
            winner = Thread.new { instance.features }
            wait_for(entered)
            losers = 8.times.map { Thread.new { instance.features } }
            losers.each { |thread| join_thread(thread) }

            raise "inherited mutex was replaced" unless instance.instance_variable_get(:@mutex).equal?(mutex)
            raise "loser did not receive trusted snapshot" unless losers.map(&:value).all? { |features| features == Set["existing"] }
            raise "duplicate synchronization" unless calls[0] == 1

            release_sync << true
            join_thread(winner)
            raise "winner did not publish synchronized state" unless winner.value == Set["updated"]
            raise "inherited syncing was not cleared" if instance.instance_variable_get(:@syncing)
            raise "successful publication stayed failed" if instance.instance_variable_get(:@sync_failed)
            success = true
          rescue => error
            warn error.full_message
          ensure
            release_sync << true
            winner&.join(1)
            losers.each { |thread| thread.join(1) }
          end
          exit!(success ? 0 : 1)
        end

        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
        status = nil
        until status
          if result = Process.wait2(child_pid, Process::WNOHANG)
            _, status = result
          elsif Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
            Process.kill("KILL", child_pid)
            Process.wait(child_pid)
            raise "forked child timed out"
          else
            sleep 0.01
          end
        end
      ensure
        release_mutex << true
        holder.join(1)
      end

      exit(status.success? ? 0 : 1)
    RUBY

    _, stderr, status = Open3.capture3(
      RbConfig.ruby,
      "-Ilib",
      "-e",
      script,
      chdir: File.expand_path("../../..", __dir__)
    )

    expect(status).to be_success, stderr
  end

  it "retains the trusted snapshot after forking during a partial update" do
    Flipper.new(local_adapter).enable(:existing)

    remote = Flipper::Adapters::Memory.new(threadsafe: true)
    Flipper.new(remote).disable(:existing)
    Flipper.new(remote).enable(:updated)
    retry_entered = Queue.new
    release_retry = Queue.new
    pausing_remote_adapter = Class.new do
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
    end.new(remote.get_all, retry_entered, release_retry)

    fake_poller = build_poller(pausing_remote_adapter)

    instance = described_class.new(fake_poller, local_adapter)
    parent_pid = instance.instance_variable_get(:@pid)
    Flipper.new(local_adapter).disable(:existing)
    instance.instance_variable_set(:@syncing, true)
    allow(Process).to receive(:pid).and_return(parent_pid + 1)

    retrying = Thread.new { instance.features }
    retry_entered.pop

    expect(Flipper.new(instance).enabled?(:existing)).to be(true)
    release_retry << true
    expect(retrying.value).to eq(Set["existing", "updated"])
    expect(Flipper.new(instance).enabled?(:existing)).to be(false)
  ensure
    release_retry << true if release_retry
    retrying&.join
  end
end
