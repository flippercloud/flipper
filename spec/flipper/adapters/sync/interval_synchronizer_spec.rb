require "flipper/adapters/sync/interval_synchronizer"
require "open3"
require "rbconfig"

RSpec.describe Flipper::Adapters::Sync::IntervalSynchronizer do
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

  let(:events) { [] }
  let(:synchronizer) { -> { events << now } }
  let(:interval) { 10 }
  let(:now) { subject.send(:now) }

  subject { described_class.new(synchronizer, interval: interval) }

  it 'synchronizes on first call' do
    expect(events.size).to be(0)
    subject.call
    expect(events.size).to be(1)
  end

  it "only invokes wrapped synchronizer every interval seconds" do
    subject.call
    events.clear

    # move time to one millisecond less than last sync + interval
    1.upto(interval) do |i|
      allow(subject).to receive(:now).and_return(now + i - 1)
      subject.call
    end
    expect(events.size).to be(0)

    # move time to last sync + interval in milliseconds
    allow(subject).to receive(:now).and_return(now + interval)
    subject.call
    expect(events.size).to be(1)
  end

  it "does not synchronize again while a claimed interval sync is in flight" do
    entered = Queue.new
    release = Queue.new
    synchronizer = -> do
      events << now
      entered << true
      release.pop
    end
    instance = described_class.new(synchronizer, interval: interval)

    allow(instance).to receive(:now).and_return(interval)

    first_thread = Thread.new { instance.call }
    entered.pop

    completed = Queue.new
    threads = 10.times.map do
      Thread.new do
        instance.call
        completed << true
      end
    end
    threads.size.times { wait_for(completed) }

    expect(events.size).to eq(1)

    release << true
    ([first_thread] + threads).each { |thread| join_thread(thread) }

    expect(events.size).to eq(1)
  ensure
    11.times { release << true } if release
    ([first_thread] + Array(threads)).compact.each { |thread| thread.join(1) }
  end

  it "does not synchronize again when the interval passes during an in-flight sync" do
    current_time = interval
    entered = Queue.new
    release = Queue.new
    synchronizer = -> do
      events << current_time
      entered << true
      release.pop
    end
    instance = described_class.new(synchronizer, interval: interval)

    allow(instance).to receive(:now) { current_time }

    first_thread = Thread.new { instance.call }
    entered.pop

    current_time += interval
    completed = Queue.new
    second_thread = Thread.new do
      instance.call
      completed << true
    end
    wait_for(completed)

    expect(events.size).to eq(1)

    release << true
    [first_thread, second_thread].each { |thread| join_thread(thread) }

    expect(events.size).to eq(1)
  ensure
    2.times { release << true } if release
    [first_thread, second_thread].compact.each { |thread| thread.join(1) }
  end

  it "releases a failed sync for the next interval" do
    current_time = interval
    calls = 0
    synchronizer = -> do
      calls += 1
      raise "transient failure" if calls == 1
    end
    instance = described_class.new(synchronizer, interval: interval)
    allow(instance).to receive(:now) { current_time }

    expect { instance.call }.to raise_error("transient failure")
    instance.call
    expect(calls).to eq(1)

    current_time += interval
    instance.call
    expect(calls).to eq(2)
  end

  it "resets in-flight synchronization state after a fork" do
    entered = Queue.new
    release = Queue.new
    synchronizer = -> do
      events << now
      entered << true
      release.pop
    end
    instance = described_class.new(synchronizer, interval: interval)
    mutex = instance.instance_variable_get(:@mutex)
    parent_pid = instance.instance_variable_get(:@pid)
    instance.instance_variable_set(:@syncing, true)

    allow(instance).to receive(:now).and_return(interval)
    allow(Process).to receive(:pid).and_return(parent_pid + 1)

    threads = 10.times.map { Thread.new { instance.call } }
    entered.pop
    release << true
    threads.each(&:join)

    expect(events.size).to eq(1)
    expect(instance.instance_variable_get(:@pid)).to eq(parent_pid + 1)
    expect(instance.instance_variable_get(:@mutex)).to equal(mutex)
  end

  it "keeps its mutex and elects one winner in a real forked child" do
    skip "Process.fork is not supported" unless Process.respond_to?(:fork)

    script = <<~'RUBY'
      require "flipper/adapters/sync/interval_synchronizer"

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

      entered = Queue.new
      release_sync = Queue.new
      calls = [0]
      synchronizer = lambda do
        calls[0] += 1
        entered << true
        release_sync.pop
      end
      instance = Flipper::Adapters::Sync::IntervalSynchronizer.new(synchronizer, interval: 10)
      mutex = instance.instance_variable_get(:@mutex)
      raise "interval synchronizer does not use a stable Mutex" unless mutex.instance_of?(Mutex)
      instance.instance_variable_set(:@syncing, true)

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
            winner = Thread.new { instance.call }
            wait_for(entered)
            losers = 8.times.map { Thread.new { instance.call } }
            losers.each { |thread| join_thread(thread) }

            raise "inherited mutex was replaced" unless instance.instance_variable_get(:@mutex).equal?(mutex)
            raise "duplicate synchronization" unless calls[0] == 1

            release_sync << true
            join_thread(winner)
            raise "inherited syncing was not cleared" if instance.instance_variable_get(:@syncing)
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
      chdir: File.expand_path("../../../..", __dir__)
    )

    expect(status).to be_success, stderr
  end
end
