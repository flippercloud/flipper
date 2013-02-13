require 'helper'
require 'flipper/instrumenters/memory'

describe Flipper::Gates::PercentageOfRandom do
  let(:adapter) { double('Adapter', :read => 5) }
  let(:feature) { double('Feature', :key => 'search', :name => :search, :adapter => adapter) }
  let(:instrumenter) { Flipper::Instrumenters::Memory.new }

  subject {
    described_class.new(feature, :instrumenter => instrumenter)
  }

  describe "instrumentation" do
    it "is recorded for open" do
      thing = Struct.new(:flipper_id).new('22')
      subject.open?(thing, 0)

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('gate_operation.flipper')

      event.payload[:thing].should eq(thing)
      event.payload[:operation].should eq(:open?)
      event.payload[:gate_name].should eq(:percentage_of_random)
      event.payload[:feature_name].should eq(:search)

      # random so don't test value
      event.payload.key?(:result).should be_true
      event.payload[:result].should_not be_nil
    end
  end

  describe "#description" do
    context "when enabled" do
      it "returns text" do
        subject.description(22).should eq('22% of the time')
      end
    end

    context "when disabled" do
      it "returns disabled" do
        subject.description(nil).should eq('disabled')
        subject.description(0).should eq('disabled')
      end
    end
  end
end
