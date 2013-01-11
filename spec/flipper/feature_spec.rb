require 'helper'
require 'flipper/feature'
require 'flipper/adapters/memory'

describe Flipper::Feature do
  subject           { described_class.new(:search, adapter) }

  let(:source)      { {} }
  let(:adapter)     { Flipper::Adapters::Memory.new(source) }

  it "initializes with name and adapter" do
    feature = described_class.new(:search, adapter)
    feature.name.should eq(:search)
    feature.adapter.should eq(Flipper::Adapter.wrap(adapter))
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

  context "#disabled?" do
    it "returns the opposite of enabled" do
      subject.stub(:enabled? => true)
      subject.disabled?.should be_false

      subject.stub(:enabled? => false)
      subject.disabled?.should be_true
    end
  end
end
