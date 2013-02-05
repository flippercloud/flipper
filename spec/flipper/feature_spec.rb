require 'helper'
require 'flipper/feature'
require 'flipper/adapters/memory'
require 'flipper/instrumenters/memory'

describe Flipper::Feature do
  subject { described_class.new(:search, adapter) }

  let(:source) { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }

  describe "#initialize" do
    it "sets name" do
      feature = described_class.new(:search, adapter)
      feature.name.should eq(:search)
    end

    it "sets adapter" do
      feature = described_class.new(:search, adapter)
      feature.adapter.should eq(Flipper::Adapter.wrap(adapter))
    end

    it "defaults instrumenter" do
      feature = described_class.new(:search, adapter)
      feature.instrumenter.should be(Flipper::Instrumenters::Noop)
    end

    context "with overriden instrumenter" do
      let(:instrumenter) { double('Instrumentor', :instrument => nil) }

      it "overrides default instrumenter" do
        feature = described_class.new(:search, adapter, {
          :instrumenter => instrumenter,
        })
        feature.instrumenter.should be(instrumenter)
      end

      it "passes overridden instrumenter to adapter wrapping" do
        feature = described_class.new(:search, adapter, {
          :instrumenter => instrumenter,
        })
        feature.adapter.instrumenter.should be(instrumenter)
      end
    end
  end

  describe "#gate_for" do
    context "with percentage of actors" do
      it "returns percentage of actors gate" do
        percentage = Flipper::Types::PercentageOfActors.new(10)
        gate = subject.gate_for(percentage)
        gate.should be_instance_of(Flipper::Gates::PercentageOfActors)
      end
    end
  end

  describe "#gates" do
    it "returns array of gates with each gate's instrumenter set" do
      instrumenter = double('Instrumenter')
      instance = described_class.new(:search, adapter, :instrumenter => instrumenter)
      instance.gates.should be_instance_of(Array)
      instance.gates.each do |gate|
        gate.should be_a(Flipper::Gate)
        gate.instrumenter.should be(instrumenter)
      end
      instance.gates.size.should be(5)
    end
  end

  context "#enabled?" do
    it "returns the same as any_gates_open" do
      subject.stub(:any_gates_open? => true)
      subject.enabled?.should be_true

      subject.stub(:any_gates_open? => false)
      subject.enabled?.should be_false
    end
  end

  describe "#inspect" do
    it "returns easy to read string representation" do
      string = subject.inspect
      string.should include('Flipper::Feature')
      string.should include('name=:search')
      string.should include('state=:off')
      string.should include("adapter=#{subject.adapter.name.inspect}")
    end
  end

  describe "instrumentation" do
    let(:instrumenter) { Flipper::Instrumenters::Memory.new }

    subject {
      described_class.new(:search, adapter, :instrumenter => instrumenter)
    }

    it "is recorded for enable" do
      thing = Flipper::Types::Boolean.new
      gate = subject.gate_for(thing)

      subject.enable(thing)

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('feature_operation.flipper')
      event.payload[:feature_name].should eq(:search)
      event.payload[:operation].should eq(:enable)
      event.payload[:thing].should eq(thing)
      event.payload[:result].should_not be_nil
    end

    it "is recorded for disable" do
      thing = Flipper::Types::Boolean.new
      gate = subject.gate_for(thing)

      subject.disable(thing)

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('feature_operation.flipper')
      event.payload[:feature_name].should eq(:search)
      event.payload[:operation].should eq(:disable)
      event.payload[:thing].should eq(thing)
      event.payload[:result].should_not be_nil
    end

    it "is recorded for enabled?" do
      thing = Flipper::Types::Boolean.new
      gate = subject.gate_for(thing)

      subject.enabled?(thing)

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('feature_operation.flipper')
      event.payload[:feature_name].should eq(:search)
      event.payload[:operation].should eq(:enabled?)
      event.payload[:thing].should eq(thing)
      event.payload[:result].should be_false
    end
  end

  describe "#state" do
    context "fully on" do
      before do
        subject.enable
      end

      it "returns :on" do
        subject.state.should be(:on)
      end
    end

    context "fully off" do
      before do
        subject.disable
      end

      it "returns :off" do
        subject.state.should be(:off)
      end
    end

    context "partially on" do
      before do
        subject.enable Flipper::Types::PercentageOfRandom.new(5)
      end

      it "returns :conditional" do
        subject.state.should be(:conditional)
      end
    end
  end

  describe "#description" do
    context "fully on" do
      before do
        subject.enable
      end

      it "returns enabled" do
        subject.description.should eq('Enabled')
      end
    end

    context "fully off" do
      before do
        subject.disable
      end

      it "returns disabled" do
        subject.description.should eq('Disabled')
      end
    end

    context "partially on" do
      before do
        actor = Struct.new(:flipper_id).new(5)
        subject.enable Flipper::Types::PercentageOfRandom.new(5)
        subject.enable actor
      end

      it "returns text" do
        subject.description.should eq('Enabled for actors (5), 5% of the time')
      end
    end
  end
end
