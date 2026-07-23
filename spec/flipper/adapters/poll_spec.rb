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

  it "waits for an in-flight poller update before returning the adapter" do
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
    sleep 0.05

    expect(completed).to be_empty

    release << true
    expect(first_thread.value).to eq(Set["updated"])
    expect(completed.pop).to eq(Set["updated"])
    second_thread.join
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
    instance.instance_variable_set(:@syncing, true)

    allow(Process).to receive(:pid).and_return(instance.instance_variable_get(:@pid) + 1)

    expect(instance.features).to eq(Set["updated"])
    expect(get_all_calls.value).to eq(1)
  end
end
