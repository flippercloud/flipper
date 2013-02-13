require 'helper'
require 'flipper/instrumenters/memory'

describe Flipper::Gates::Boolean do
  let(:adapter) { double('Adapter', :read => nil) }
  let(:feature) { double('Feature', :name => :search, :adapter => adapter) }
  let(:instrumenter) { Flipper::Instrumenters::Memory.new }

  subject {
    described_class.new(feature, :instrumenter => instrumenter)
  }

  describe "#value" do
    it "returns value" do
      subject.value.should be(false)
    end
  end

  describe "#description" do
    context "for enabled" do
      before do
        subject.stub(:enabled? => true)
      end

      it "returns Enabled" do
        subject.description.should eq('Enabled')
      end
    end

    context "for disabled" do
      before do
        subject.stub(:enabled? => false)
      end

      it "returns Disabled" do
        subject.description.should eq('Disabled')
      end
    end
  end

  describe "instrumentation" do
    it "is recorded for open" do
      thing = nil
      subject.open?(thing, false)

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('gate_operation.flipper')
      event.payload.should eq({
        :thing => thing,
        :operation => :open?,
        :result => false,
        :gate_name => :boolean,
        :feature_name => :search,
      })
    end
  end
end
