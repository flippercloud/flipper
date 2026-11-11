require "flipper/cloud/shared_memory"

RSpec.describe Flipper::Cloud::SharedMemory do
  let(:version) { Flipper::SyncVersion.new("scope", 2) }

  it "is a Memory adapter" do
    expect(subject).to be_a(Flipper::Adapters::Memory)
  end

  it "has synced no version until told" do
    expect(subject.synced?(version)).to be(false)
    expect(subject.synced?(nil)).to be(false)
  end

  it "remembers the last synced version" do
    subject.synced(version)

    expect(subject.synced?(Flipper::SyncVersion.new("scope", 2))).to be(true)
    expect(subject.synced?(Flipper::SyncVersion.new("scope", 3))).to be(false)
    expect(subject.synced?(nil)).to be(false)
  end
end
