RSpec.describe Flipper::AdapterBuilder do
  describe "#use" do
    it "wraps the store adapter with the given adapter" do
      subject.use(Flipper::Adapters::Memoizable)
      subject.use(Flipper::Adapters::Strict, handler: :warn)

      memoizable_adapter = subject.to_adapter
      strict_adapter = memoizable_adapter.adapter
      memory_adapter = strict_adapter.adapter


      expect(memoizable_adapter).to be_instance_of(Flipper::Adapters::Memoizable)
      expect(strict_adapter).to be_instance_of(Flipper::Adapters::Strict)
      expect(strict_adapter.handler).to be(Flipper::Adapters::Strict::HANDLERS.fetch(:warn))
      expect(memory_adapter).to be_instance_of(Flipper::Adapters::Memory)
    end
  end

  describe "#store" do
    it "defaults to memory adapter" do
      expect(subject.to_adapter).to be_instance_of(Flipper::Adapters::Memory)
    end

    it "only saves one store" do
      require "flipper/adapters/pstore"
      subject.store(Flipper::Adapters::PStore)
      expect(subject.to_adapter).to be_instance_of(Flipper::Adapters::PStore)

      subject.store(Flipper::Adapters::Memory)
      expect(subject.to_adapter).to be_instance_of(Flipper::Adapters::Memory)
    end
  end
end
