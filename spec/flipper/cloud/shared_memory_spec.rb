require "flipper/cloud/shared_memory"

RSpec.describe Flipper::Cloud::SharedMemory do
  def version(number)
    Flipper::SyncVersion.new("scope", number)
  end

  it "records a version once its sync finishes, never nil" do
    expect(subject.synced?(version(2))).to be(false)

    subject.sync(version(2)) {}
    expect(subject.synced?(version(2))).to be(true)
    expect(subject.synced?(version(3))).to be(false)

    subject.sync(nil) {}
    expect(subject.synced?(nil)).to be(false)
  end

  it "records nothing when the sync raises" do
    expect { subject.sync(version(2)) { raise "database down" } }.to raise_error("database down")
    expect(subject.synced?(version(2))).to be(false)
  end

  # An older sync can write its flags after a newer one, so neither may mark
  # its version synced. The next poll syncs again and repairs the store.
  it "records nothing when syncs overlap" do
    started = Queue.new
    finish = Queue.new
    older = Thread.new do
      Thread.current.abort_on_exception = true
      subject.sync(version(2)) do
        started << true
        finish.pop
      end
    end
    started.pop

    subject.sync(version(3)) {}
    finish << true
    older.join

    expect(subject.synced?(version(2))).to be(false)
    expect(subject.synced?(version(3))).to be(false)

    subject.sync(version(3)) {}
    expect(subject.synced?(version(3))).to be(true)
  end
end
