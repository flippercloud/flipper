require 'helper'
require 'flipper/feature'
require 'flipper/adapters/memory'
require 'flipper/instrumentors/memory'

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

    it "defaults instrumentor" do
      feature = described_class.new(:search, adapter)
      feature.instrumentor.should be(Flipper::Instrumentors::Noop)
    end

    context "with overriden instrumentor" do
      let(:instrumentor) { double('Instrumentor', :instrument => nil) }

      it "overrides default instrumentor" do
        feature = described_class.new(:search, adapter, {
          :instrumentor => instrumentor,
        })
        feature.instrumentor.should be(instrumentor)
      end

      it "passes overridden instrumentor to adapter wrapping" do
        feature = described_class.new(:search, adapter, {
          :instrumentor => instrumentor,
        })
        feature.adapter.instrumentor.should be(instrumentor)
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
    it "returns array of gates" do
      subject.gates.should be_instance_of(Array)
      subject.gates.each do |gate|
        gate.should be_a(Flipper::Gate)
      end
      subject.gates.size.should be(5)
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

  context "#disabled?" do
    it "returns the opposite of any_gates_open" do
      subject.stub(:any_gates_open? => true)
      subject.disabled?.should be_false

      subject.stub(:any_gates_open? => false)
      subject.disabled?.should be_true
    end
  end

  describe "#inspect" do
    it "returns easy to read string representation" do
      string = subject.inspect
      string.should include('Flipper::Feature')
      string.should include('name=:search')
      string.should include('adapter="memory"')
    end
  end

  describe "instrumentation" do
    let(:instrumentor) { Flipper::Instrumentors::Memory.new }

    subject {
      described_class.new(:search, adapter, :instrumentor => instrumentor)
    }

    it "is recorded for enable" do
      thing = Flipper::Types::Boolean.new
      gate = subject.gate_for(thing)

      subject.enable(thing)

      event = instrumentor.events.last
      event.should_not be_nil
      event.name.should eq('enable.search.feature.flipper')
      event.payload.should eq({
        :feature_name => :search,
        :thing => thing,
        :gate => gate,
      })
    end

    it "is recorded for disable" do
      thing = Flipper::Types::Boolean.new
      gate = subject.gate_for(thing)

      subject.disable(thing)

      event = instrumentor.events.last
      event.should_not be_nil
      event.name.should eq('disable.search.feature.flipper')
      event.payload.should eq({
        :feature_name => :search,
        :thing => thing,
        :gate => gate,
      })
    end

    it "is recorded for enabled?" do
      thing = Flipper::Types::Boolean.new
      gate = subject.gate_for(thing)

      subject.enabled?(thing)

      event = instrumentor.events.last
      event.should_not be_nil
      event.name.should eq('enabled.search.feature.flipper')
      event.payload.should eq({
        :feature_name => :search,
        :thing => thing,
      })
    end

    it "is recorded for disabled?" do
      thing = Flipper::Types::Boolean.new
      gate = subject.gate_for(thing)

      subject.disabled?(thing)

      event = instrumentor.events.last
      event.should_not be_nil
      event.name.should eq('disabled.search.feature.flipper')
      event.payload.should eq({
        :feature_name => :search,
        :thing => thing,
      })
    end
  end
end
