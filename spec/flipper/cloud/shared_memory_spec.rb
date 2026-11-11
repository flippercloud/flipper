require "flipper/cloud/shared_memory"

RSpec.describe Flipper::Cloud::SharedMemory do
  it "remembers the last synced version, never nil" do
    expect(subject.synced?(Flipper::SyncVersion.new("scope", 2))).to be(false)
    expect(subject.synced?(nil)).to be(false)

    subject.synced(Flipper::SyncVersion.new("scope", 2))

    expect(subject.synced?(Flipper::SyncVersion.new("scope", 2))).to be(true)
    expect(subject.synced?(Flipper::SyncVersion.new("scope", 3))).to be(false)
    expect(subject.synced?(nil)).to be(false)
  end
end
