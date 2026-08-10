require "flipper/fork_safe_mutex"
require "open3"
require "rbconfig"
require "timeout"

RSpec.describe Flipper::ForkSafeMutex do
  subject { described_class.new }

  it "synchronizes using its mutex" do
    ran = false
    subject.synchronize { ran = true }
    expect(ran).to be(true)
  end

  it "synchronizes without consulting the atomic state in the same process" do
    state = subject.instance_variable_get(:@state)

    expect(state).not_to receive(:get)
    subject.synchronize {}
  end

  it "synchronizes without blocking when the mutex is available" do
    ran = false

    expect(subject.try_synchronize { ran = true }).to be(true)
    expect(ran).to be(true)
  end

  it "does not synchronize when the mutex is already locked" do
    mutex = subject.instance_variable_get(:@current).mutex
    mutex.lock

    expect(subject.try_synchronize {}).to be(false)
  ensure
    mutex&.unlock
  end

  it "unlocks after the synchronized block raises" do
    expect do
      subject.try_synchronize { raise "boom" }
    end.to raise_error(RuntimeError, "boom")

    expect(subject.try_synchronize {}).to be(true)
  end

  it "unlocks after a non-local return from the synchronized block" do
    call = lambda do
      subject.try_synchronize { return :returned }
      :not_returned
    end

    expect(call.call).to eq(:returned)
    expect(subject.try_synchronize {}).to be(true)
  end

  it "is not forked within the same process" do
    expect(subject.forked?).to be(false)
    expect(subject.reset_if_forked).to be(false)
  end

  it "swaps in a fresh mutex after a fork instead of unlocking a stale one" do
    original = subject.instance_variable_get(:@current).mutex
    locked = Queue.new
    release = Queue.new
    thread = Thread.new do
      original.lock
      locked << true
      release.pop
      original.unlock
    end

    locked.pop
    allow(Process).to receive(:pid).and_return(Process.pid + 1)

    expect(subject.reset_if_forked).to be(true)
    expect(subject.instance_variable_get(:@current).mutex).not_to equal(original)
    expect { subject.synchronize {} }.not_to raise_error
  ensure
    release << true if release
    thread&.join
  end

  it "synchronizes in a forked child while the inherited mutex is locked" do
    skip "Process.fork is not supported" unless Process.respond_to?(:fork)

    script = <<~'RUBY'
      require "flipper/fork_safe_mutex"

      fork_safe_mutex = Flipper::ForkSafeMutex.new
      inherited_mutex = fork_safe_mutex.instance_variable_get(:@current).mutex
      locked = Queue.new
      release = Queue.new
      thread = Thread.new do
        inherited_mutex.lock
        locked << true
        release.pop
        inherited_mutex.unlock
      end
      locked.pop

      child_pid = fork do
        fork_safe_mutex.synchronize {}
        exit! 0
      end
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2
      status = nil
      until status
        if result = Process.wait2(child_pid, Process::WNOHANG)
          _, status = result
        elsif Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
          Process.kill("KILL", child_pid)
          Process.wait(child_pid)
          warn "forked child timed out"
          exit 1
        else
          sleep 0.01
        end
      end

      release << true
      thread.join
      exit(status.success? ? 0 : 1)
    RUBY

    _, stderr, status = Open3.capture3(
      RbConfig.ruby,
      "-Ilib",
      "-e",
      script,
      chdir: File.expand_path("../..", __dir__)
    )

    expect(status).to be_success, stderr
  end

  it "keeps the winning mutex when two resets race on the same fork" do
    state = subject.instance_variable_get(:@state)
    stale = state.get
    allow(Process).to receive(:pid).and_return(stale.pid + 1)
    ready = Queue.new
    release = Queue.new
    calls = Concurrent::AtomicFixnum.new(0)

    allow(state).to receive(:get).and_wrap_original do |original|
      value = original.call
      if calls.increment <= 2
        ready << true
        release.pop
      end
      value
    end

    threads = 2.times.map do
      Thread.new { subject.reset_if_forked }
    end

    results = Timeout.timeout(2) do
      2.times { ready.pop }
      2.times { release << true }
      threads.map(&:value)
    end
    expect(results).to eq([true, true])

    winner = state.get
    expect(winner.pid).to eq(Process.pid)
    expect(winner.mutex).not_to equal(stale.mutex)
    expect(subject.instance_variable_get(:@current)).to equal(winner)
  ensure
    2.times { release << true } if release
    threads&.each { |thread| thread.join(1) }
  end
end
