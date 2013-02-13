require 'helper'
require 'flipper/instrumenters/memory'

describe Flipper::Gates::Actor do
  let(:adapter) { double('Adapter', :set_members => []) }
  let(:feature) { double('Feature', :key => 'search', :name => :search, :adapter => adapter) }
  let(:instrumenter) { Flipper::Instrumenters::Memory.new }

  subject {
    described_class.new(feature, :instrumenter => instrumenter)
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
      before do
        adapter.stub(:set_members => Set['bacon', 'ham'])
      end

      it "returns text" do
        subject.description.should eq('actors ("bacon", "ham")')
      end
    end

    context "with no actors in set" do
      before do
        adapter.stub(:set_members => Set.new)
      end

      it "returns disabled" do
        subject.description.should eq('disabled')
      end
    end
  end
end
