RSpec.describe Flipper::AdapterBuilder do
  describe "#initialize" do
    it "instance_eval's block with no arg" do
      called = false
      self_in_block = nil

      described_class.new do
        called = true
        self_in_block = self
      end

      expect(self_in_block).to be_instance_of(described_class)
      expect(called).to be(true)
    end

    it "evals block with arg" do
      called = false
      self_outside_block = self
      self_in_block = nil

      described_class.new do |arg|
        called = true
        self_in_block = self
        expect(arg).to be_instance_of(described_class)
      end

      expect(self_in_block).to be(self_outside_block)
      expect(called).to be(true)
    end
  end

  describe "#use" do
    it "wraps the store adapter with the given adapter" do
      subject.use(Flipper::Adapters::Memoizable)
      subject.use(Flipper::Adapters::Strict, :warn)

      memoizable_adapter = subject.to_adapter
      strict_adapter = memoizable_adapter.adapter
      memory_adapter = strict_adapter.adapter

      expect(memoizable_adapter).to be_instance_of(Flipper::Adapters::Memoizable)
      expect(strict_adapter).to be_instance_of(Flipper::Adapters::Strict)
      expect(strict_adapter.handler).to be(:warn)
      expect(memory_adapter).to be_instance_of(Flipper::Adapters::Memory)
    end

    it "passes block to adapter initializer" do
      expected_block = lambda {}
      adapter_class = double('adapter class')

      subject.use(adapter_class, &expected_block)

      expect(adapter_class).to receive(:new) { |&block| expect(block).to be(expected_block) }.and_return(:adapter)
      expect(subject.to_adapter).to be(:adapter)
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

  describe "#wrap_store" do
    it "wraps storage beneath adapters added with use" do
      subject.use(Flipper::Adapters::Strict, :warn)
      subject.wrap_store(:example) do |adapter|
        Flipper::Adapters::Memoizable.new(adapter)
      end

      strict = subject.to_adapter
      expect(strict).to be_instance_of(Flipper::Adapters::Strict)
      expect(strict.adapter).to be_instance_of(Flipper::Adapters::Memoizable)
      expect(strict.adapter.adapter).to be_instance_of(Flipper::Adapters::Memory)
    end

    it "continues wrapping when the store is reconfigured" do
      require "flipper/adapters/pstore"
      subject.wrap_store(:example) do |adapter|
        Flipper::Adapters::Memoizable.new(adapter)
      end
      subject.store(Flipper::Adapters::PStore)

      wrapped = subject.to_adapter
      expect(wrapped).to be_instance_of(Flipper::Adapters::Memoizable)
      expect(wrapped.adapter).to be_instance_of(Flipper::Adapters::PStore)
    end

    it "only adds a keyed wrapper once" do
      subject.wrap_store(:example) do |adapter|
        Flipper::Adapters::Memoizable.new(adapter)
      end
      subject.wrap_store(:example) do |adapter|
        Flipper::Adapters::Strict.new(adapter, :warn)
      end

      wrapped = subject.to_adapter
      expect(wrapped).to be_instance_of(Flipper::Adapters::Memoizable)
      expect(wrapped.adapter).to be_instance_of(Flipper::Adapters::Memory)
    end
  end
end
