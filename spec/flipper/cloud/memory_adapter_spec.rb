require "flipper/cloud/memory_adapter"
require "flipper/cloud/shared_memory"
require "flipper/adapters/operation_logger"

RSpec.describe Flipper::Cloud::MemoryAdapter do
  let(:store) { Flipper::Adapters::OperationLogger.new(Flipper::Adapters::Memory.new) }
  let(:memory) { Flipper::Cloud::SharedMemory.new }
  let(:version) { Flipper::SyncVersion.new("scope", 10) }

  subject { described_class.new(store, memory) }

  it_should_behave_like "a flipper adapter"
  it_should_behave_like "an adapter that stores its sync version"

  it "reads only from memory" do
    Flipper.new(memory).enable(:search)
    store.reset

    flipper = Flipper.new(subject, memoize: false)
    expect(flipper.enabled?(:search)).to be(true)
    expect(flipper.features.map(&:key)).to eq(["search"])
    flipper.preload_all
    flipper.preload([:search])

    expect(store.operations).to be_empty
  end

  it "writes to the adapter, then memory" do
    Flipper.new(subject).enable_actor(:search, Flipper::Actor.new("User;1"))

    expect(store.get_all).to eq(memory.get_all)
    expect(memory.get_all["search"][:actors]).to eq(Set["User;1"])
  end

  it "leaves memory alone when the adapter write fails" do
    allow(store).to receive(:enable).and_raise("down")

    expect { Flipper.new(subject).enable(:search) }.to raise_error("down")
    expect(memory.get_all["search"][:boolean]).to be_nil
  end

  it "reads the sync version from the adapter and writes it to both" do
    memory.sync_version = Flipper::SyncVersion.new("scope", 99)
    expect(subject.sync_version).to be_nil

    subject.sync_version = version
    expect(store.sync_version).to eq(version)
    expect(memory.sync_version).to eq(version)
  end

  describe "with refresh_interval" do
    let(:now) { [100] }

    subject { described_class.new(store, memory, refresh_interval: 10) }

    before do
      allow(Process).to receive(:clock_gettime).and_call_original
      allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC, :second) { now.first }
      subject
      Flipper.new(store).enable(:search)
      store.sync_version = version
    end

    it "reloads memory from the adapter once the interval passes" do
      expect(subject.get_all).to eq({})

      now[0] = 110
      expect(subject.get_all.keys).to eq(["search"])
      expect(memory.features).to eq(Set["search"])
    end

    it "keeps serving memory while the adapter is down" do
      Flipper.new(memory).enable(:analytics)
      allow(store).to receive(:get_all).and_raise("down")

      now[0] = 110
      expect(subject.features).to eq(Set["analytics"])
    end

    it "leaves memory alone when the adapter was never synced" do
      store.sync_version = nil
      Flipper.new(memory).enable(:analytics)

      now[0] = 110
      expect(subject.features).to eq(Set["analytics"])
    end

    it "keeps memory when the adapter has the same version" do
      # A failed sync can leave the adapter with the version but not all flags.
      memory.sync_version = version
      Flipper.new(memory).enable(:analytics)

      now[0] = 110
      expect(subject.features).to eq(Set["analytics"])
    end

    it "keeps newer flags in memory than the adapter's" do
      memory.sync_version = Flipper::SyncVersion.new("scope", 11)

      now[0] = 110
      expect(subject.features).to be_empty
    end
  end
end
