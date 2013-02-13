require 'helper'
require 'flipper/instrumenters/memory'

describe Flipper::Gates::Group do
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
        :gate_name => :group,
        :feature_name => :search,
      })
    end
  end

  describe "#description" do
    context "with groups in set" do
      it "returns text" do
        values = Set['bacon', 'ham']
        subject.description(values).should eq('groups (:bacon, :ham)')
      end
    end

    context "with no groups in set" do
      it "returns disabled" do
        subject.description(Set.new).should eq('disabled')
      end
    end
  end

  describe "#open?" do
    context "with a group in adapter, but not registered" do
      before do
        Flipper.register(:staff) { |thing| true }
      end

      it "ignores group" do
        thing = Struct.new(:flipper_id).new('5')
        subject.open?(thing, Set[:newbs, :staff]).should be_true
      end
    end

    context "thing that does not respond to method in group block" do
      before do
        Flipper.register(:stinkers) { |thing| thing.stinker? }
      end

      it "raises error" do
        expect {
          subject.open?(Object.new, Set[:stinkers])
        }.to raise_error(NoMethodError)
      end
    end
  end
end
