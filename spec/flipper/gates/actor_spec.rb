require 'helper'
require 'flipper/instrumenters/memory'

describe Flipper::Gates::Actor do
  let(:instrumenter) { Flipper::Instrumenters::Memory.new }
  let(:feature_name) { :search }

  subject {
    described_class.new(feature_name, :instrumenter => instrumenter)
  }

  describe "instrumentation" do
    it "is recorded for open" do
      thing = Struct.new(:flipper_id).new('22')
      subject.open?(thing, Set.new)

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('gate_operation.flipper')
      event.payload.should eq({
        :thing => thing,
        :operation => :open?,
        :result => false,
        :gate_name => :actor,
        :feature_name => :search,
      })
    end
  end

  describe "#description" do
    context "with actors in set" do
      it "returns text" do
        values = Set['bacon', 'ham']
        subject.description(values).should eq('actors ("bacon", "ham")')
      end
    end

    context "with no actors in set" do
      it "returns disabled" do
        subject.description(Set.new).should eq('disabled')
      end
    end
  end
end
