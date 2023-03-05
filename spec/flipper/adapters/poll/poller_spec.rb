require "flipper/adapters/poll/poller"

RSpec.describe Flipper::Adapters::Poll::Poller do
  let(:remote_adapter) { Flipper::Adapters::Memory.new }
  let(:remote) { Flipper.new(remote_adapter) }
  let(:local) { Flipper.new(subject.adapter) }

  subject do
    described_class.new(
      remote_adapter: remote_adapter,
      start_automatically: false,
      interval: Float::INFINITY
    )
  end

  describe "#adapter" do
    it "always returns same memory adapter instance" do
      expect(subject.adapter).to be_a(Flipper::Adapters::Memory)
      expect(subject.adapter.object_id).to eq(subject.adapter.object_id)
      expect(subject.adapter.get_all.object_id).to eq(subject.adapter.get_all.object_id)
    end
  end

  describe "#sync" do
    it "syncs remote adapter to local adapter" do
      remote.enable :polling

      expect(local.enabled?(:polling)).to be(false)
      subject.sync
      expect(local.enabled?(:polling)).to be(true)
    end
  end
end
