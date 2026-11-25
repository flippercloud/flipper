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

  # Every thread syncs a new version after the poll that brings it, so they
  # overlap. They write the same flags, so one of them records it.
  it "records a version that several threads synced at the same time" do
    started = Queue.new
    finish = Queue.new
    first = Thread.new do
      Thread.current.abort_on_exception = true
      subject.sync(version(2)) do
        started << true
        finish.pop
      end
    end
    started.pop

    subject.sync(version(2)) {}
    finish << true
    first.join

    expect(subject.synced?(version(2))).to be(true)
  end

  # A thread that fails may have cleared flags it never wrote back, so the
  # version can't stay recorded or the next poll would skip the repair.
  it "forgets a version when another sync of it fails after it was recorded" do
    started = Queue.new
    finish = Queue.new
    failing = Thread.new do
      subject.sync(version(2)) do
        started << true
        finish.pop
        raise "database down"
      end
    rescue RuntimeError
    end
    started.pop

    subject.sync(version(2)) {}
    expect(subject.synced?(version(2))).to be(true)

    finish << true
    failing.join
    expect(subject.synced?(version(2))).to be(false)
  end

  it "forgets the recorded version when a sync without a version fails" do
    subject.sync(version(2)) {}
    expect { subject.sync(nil) { raise "database down" } }.to raise_error("database down")
    expect(subject.synced?(version(2))).to be(false)
  end

  it "records nothing for a sync still running when another sync of its version fails" do
    started = Queue.new
    finish = Queue.new
    running = Thread.new do
      Thread.current.abort_on_exception = true
      subject.sync(version(2)) do
        started << true
        finish.pop
      end
    end
    started.pop

    expect { subject.sync(version(2)) { raise "database down" } }.to raise_error("database down")
    finish << true
    running.join

    expect(subject.synced?(version(2))).to be(false)
  end

  it "records nothing when a sync of another version starts during one of the same version" do
    started = Queue.new
    finish = Queue.new
    threads = 2.times.map do
      Thread.new do
        Thread.current.abort_on_exception = true
        subject.sync(version(2)) do
          started << true
          finish.pop
        end
      end
    end
    2.times { started.pop }

    subject.sync(version(3)) {}
    2.times { finish << true }
    threads.each(&:join)

    expect(subject.synced?(version(2))).to be(false)
    expect(subject.synced?(version(3))).to be(false)
  end

  it "lets one caller claim the store check for each poll" do
    expect(subject.claim_store_check(10.0)).to be(true)
    expect(subject.claim_store_check(10.0)).to be(false)
    expect(subject.claim_store_check(20.0)).to be(true)
  end

  it "never lets an older poll take the store check back from a newer one" do
    subject.claim_store_check(20.0)
    expect(subject.claim_store_check(10.0)).to be(false)
    expect(subject.claim_store_check(20.0)).to be(false)
  end

  it "lets another caller claim a poll whose check was given back" do
    subject.claim_store_check(10.0)
    subject.release_store_check(10.0)
    expect(subject.claim_store_check(10.0)).to be(true)
  end

  describe "#reload" do
    let(:store) { Flipper::Adapters::Memory.new }
    let(:now) { [100] }

    before do
      allow(Process).to receive(:clock_gettime).and_call_original
      allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC, :float_second) { now.first }
      Flipper.new(store).enable(:search)
      store.sync_version = version(2)
    end

    it "imports a new version" do
      subject.reload(store)
      expect(subject.sync_version).to eq(version(2))
      expect(subject.features).to eq(Set["search"])
    end

    it "does nothing when the store was never synced" do
      store.sync_version = nil
      subject.reload(store)
      expect(subject.features).to be_empty
    end

    # A sync writes its version before its flags, so the first copy can have
    # only some of them.
    it "copies again until a copy changes nothing an interval after the last change" do
      subject.reload(store)
      Flipper.new(store).enable(:analytics) # the sync finishes

      subject.reload(store) # too soon to copy again
      expect(subject.features).to eq(Set["search"])

      now[0] = 110
      subject.reload(store)
      expect(subject.features).to eq(Set["search", "analytics"])

      now[0] = 120
      subject.reload(store) # changes nothing
      now[0] = 130
      expect(store).not_to receive(:get_all)
      subject.reload(store)
    end

    # Threads reload on their own clocks, so a copy right after another one
    # shows nothing about whether a sync was still writing.
    it "keeps copying when a copy matches one made moments before" do
      now[0] = 100.99
      subject.reload(store)
      now[0] = 101.01
      subject.import(store, recopy: true) # another thread, moments later
      Flipper.new(store).enable(:analytics) # the sync finishes

      now[0] = 110
      subject.reload(store)
      expect(subject.features).to eq(Set["search", "analytics"])
    end

    it "waits a whole interval to copy again, not just until the next second" do
      now[0] = 100.99
      subject.reload(store)
      now[0] = 101.01
      subject.recopy(store) # too soon to copy again
      Flipper.new(store).enable(:analytics) # the sync finishes

      now[0] = 102
      subject.recopy(store)
      expect(subject.features).to eq(Set["search", "analytics"])
    end

    it "copies again on #recopy only when a copy is pending" do
      expect(store).not_to receive(:get_all)
      now[0] = 110
      subject.recopy(store)
      expect(subject.features).to be_empty
    end

    it "copies a pending copy again on #recopy" do
      subject.reload(store)
      Flipper.new(store).enable(:analytics) # the sync finishes

      now[0] = 101
      subject.recopy(store)
      expect(subject.features).to eq(Set["search", "analytics"])
    end

    it "keeps complete flags imported after a copy of the store" do
      subject.import(store, recopy: true)
      complete = Flipper::Adapters::Memory.new
      Flipper.new(complete).enable(:analytics)
      complete.sync_version = version(2)
      subject.import(complete)

      now[0] = 110
      expect(store).not_to receive(:get_all)
      subject.reload(store)
      expect(subject.features).to eq(Set["analytics"])
    end
  end
end
