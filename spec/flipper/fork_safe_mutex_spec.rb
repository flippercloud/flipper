require "flipper/fork_safe_mutex"

RSpec.describe Flipper::ForkSafeMutex do
  subject { described_class.new }

  it "synchronizes using its mutex" do
    ran = false
    subject.synchronize { ran = true }
    expect(ran).to be(true)
  end

  it "is not forked within the same process" do
    expect(subject.forked?).to be(false)
    expect(subject.reset_if_forked).to be(false)
  end

  it "swaps in a fresh mutex after a fork instead of unlocking a stale one" do
    original = subject.mutex
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
    expect(subject.mutex).not_to equal(original)
    expect { subject.synchronize {} }.not_to raise_error
  ensure
    release << true if release
    thread&.join
  end

  it "keeps the winning mutex when two resets race on the same fork" do
    stale = subject.instance_variable_get(:@state).get
    allow(Process).to receive(:pid).and_return(stale.pid + 1)

    subject.send(:reset, stale) # winner: compare_and_set against stale succeeds
    winner = subject.mutex
    subject.send(:reset, stale) # loser: stale is no longer current, so it's a no-op

    expect(subject.mutex).to equal(winner)
  end
end
