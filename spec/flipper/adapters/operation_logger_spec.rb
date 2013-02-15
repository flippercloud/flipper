require 'helper'
require 'flipper/adapters/operation_logger'
require 'flipper/adapters/memory'
require 'flipper/spec/shared_adapter_specs'

describe Flipper::Adapters::OperationLogger do
  let(:operations) { [] }
  let(:adapter)    { Flipper::Adapters::Memory.new }
  let(:flipper)    { Flipper.new(adapter) }

  subject { described_class.new(adapter, operations) }

  it_should_behave_like 'a flipper adapter'

  describe "#get" do
    before do
      @feature = flipper[:stats]
      @result = subject.get(@feature)
    end

    it "logs operation" do
      subject.count(:get).should be(1)
    end

    it "returns result" do
      @result.should eq(adapter.get(@feature))
    end
  end

  describe "#enable" do
    before do
      @feature = flipper[:stats]
      @gate = @feature.gate(:boolean)
      @thing = flipper.bool
      @result = subject.enable(@feature, @gate, @thing)
    end

    it "logs operation" do
      subject.count(:enable).should be(1)
    end

    it "returns result" do
      @result.should eq(adapter.enable(@feature, @gate, @thing))
    end
  end

  describe "#disable" do
    before do
      @feature = flipper[:stats]
      @gate = @feature.gate(:boolean)
      @thing = flipper.bool
      @result = subject.disable(@feature, @gate, @thing)
    end

    it "logs operation" do
      subject.count(:disable).should be(1)
    end

    it "returns result" do
      @result.should eq(adapter.disable(@feature, @gate, @thing))
    end
  end

  describe "#features" do
    before do
      flipper[:stats].enable
      @result = subject.features
    end

    it "logs operation" do
      subject.count(:features).should be(1)
    end

    it "returns result" do
      @result.should eq(adapter.features)
    end
  end

  describe "#add" do
    before do
      @feature = flipper[:stats]
      @result = subject.add(@feature)
    end

    it "logs operation" do
      subject.count(:add).should be(1)
    end

    it "returns result" do
      @result.should eq(adapter.add(@feature))
    end
  end
end
