require 'helper'
require 'flipper/adapters/memory'
require 'flipper/adapters/instrumented'
require 'flipper/instrumenters/memory'
require 'flipper/spec/shared_adapter_specs'

describe Flipper::Adapters::Instrumented do
  let(:instrumenter) { Flipper::Instrumenters::Memory.new }
  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:flipper) { Flipper.new(adapter) }

  let(:feature) { flipper[:stats] }
  let(:gate) { feature.gate(:percentage_of_actors) }
  let(:thing) { flipper.actors(22) }

  subject {
    described_class.new(adapter, :instrumenter => instrumenter)
  }

  it_should_behave_like 'a flipper adapter'

  describe "#get" do
    it "records instrumentation" do
      result = subject.get(feature)

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('adapter_operation.flipper')
      event.payload[:operation].should eq(:get)
      event.payload[:adapter_name].should eq(:memory)
      event.payload[:feature_name].should eq(:stats)
      event.payload[:result].should be(result)
    end
  end

  describe "#enable" do
    it "records instrumentation" do
      result = subject.enable(feature, gate, thing)

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('adapter_operation.flipper')
      event.payload[:operation].should eq(:enable)
      event.payload[:adapter_name].should eq(:memory)
      event.payload[:feature_name].should eq(:stats)
      event.payload[:gate_name].should eq(:percentage_of_actors)
      event.payload[:result].should be(result)
    end
  end

  describe "#disable" do
    it "records instrumentation" do
      result = subject.disable(feature, gate, thing)

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('adapter_operation.flipper')
      event.payload[:operation].should eq(:disable)
      event.payload[:adapter_name].should eq(:memory)
      event.payload[:feature_name].should eq(:stats)
      event.payload[:gate_name].should eq(:percentage_of_actors)
      event.payload[:result].should be(result)
    end
  end

  describe "#add" do
    it "records instrumentation" do
      result = subject.add(feature)

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('adapter_operation.flipper')
      event.payload[:operation].should eq(:add)
      event.payload[:adapter_name].should eq(:memory)
      event.payload[:feature_name].should eq(:stats)
      event.payload[:result].should be(result)
    end
  end

  describe "#remove" do
    it "records instrumentation" do
      result = subject.remove(feature)

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('adapter_operation.flipper')
      event.payload[:operation].should eq(:remove)
      event.payload[:adapter_name].should eq(:memory)
      event.payload[:feature_name].should eq(:stats)
      event.payload[:result].should be(result)
    end
  end

  describe "#clear" do
    it "records instrumentation" do
      result = subject.clear(feature)

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('adapter_operation.flipper')
      event.payload[:operation].should eq(:clear)
      event.payload[:adapter_name].should eq(:memory)
      event.payload[:feature_name].should eq(:stats)
      event.payload[:result].should be(result)
    end
  end

  describe "#features" do
    it "records instrumentation" do
      result = subject.features

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('adapter_operation.flipper')
      event.payload[:operation].should eq(:features)
      event.payload[:adapter_name].should eq(:memory)
      event.payload[:result].should be(result)
    end
  end
end
