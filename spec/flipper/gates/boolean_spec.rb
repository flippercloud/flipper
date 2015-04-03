require 'helper'
require 'flipper/instrumenters/memory'

describe Flipper::Gates::Boolean do
  let(:instrumenter) { Flipper::Instrumenters::Memory.new }
  let(:feature_name) { :search }

  subject {
    described_class.new(:instrumenter => instrumenter)
  }

  describe "#description" do
    context "for enabled" do
      it "returns Enabled" do
        subject.description(true).should eq('Enabled')
      end
    end

    context "for disabled" do
      it "returns Disabled" do
        subject.description(false).should eq('Disabled')
      end
    end
  end

  describe "#enabled?" do
    context "for true value" do
      it "returns true" do
        subject.enabled?(true).should eq(true)
      end
    end

    context "for false value" do
      it "returns false" do
        subject.enabled?(false).should eq(false)
      end
    end
  end

  describe "#open?" do
    context "for true value" do
      it "returns true" do
        subject.open?(Object.new, true, feature_name: feature_name).should eq(true)
      end
    end

    context "for false value" do
      it "returns false" do
        subject.open?(Object.new, false, feature_name: feature_name).should eq(false)
      end
    end
  end

  describe "instrumentation" do
    it "is recorded for open" do
      thing = nil
      subject.open?(thing, false, feature_name: feature_name)

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
