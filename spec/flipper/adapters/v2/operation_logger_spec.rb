require 'helper'
require 'flipper/adapters/v2/memory'
require 'flipper/adapters/v2/operation_logger'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::V2::OperationLogger do
  let(:adapter)    { Flipper::Adapters::V2::Memory.new }
  let(:flipper)    { Flipper.new(adapter) }

  subject { described_class.new(adapter) }

  it_should_behave_like 'a v2 flipper adapter'

  it "forwards missing methods to underlying adapter" do
    adapter = Class.new do
      def foo
        :foo
      end
    end.new
    operation_logger = described_class.new(adapter)
    expect(operation_logger.foo).to eq(:foo)
  end

  describe "#get" do
    before do
      @result = subject.get("foo")
    end

    it "logs operation" do
      expect(subject.count(:get)).to be(1)
    end

    it "returns result" do
      expect(@result).to eq(adapter.get("foo"))
    end
  end

  describe "#set" do
    before do
      @result = subject.set("foo", "bar")
    end

    it "logs operation" do
      expect(subject.count(:set)).to be(1)
    end

    it "returns result" do
      expect(@result).to eq(adapter.set("foo", "bar"))
    end
  end

  describe "#del" do
    before do
      @result = subject.del("foo")
    end

    it "logs operation" do
      expect(subject.count(:del)).to be(1)
    end

    it "returns result" do
      expect(@result).to eq(adapter.del("foo"))
    end
  end
end
