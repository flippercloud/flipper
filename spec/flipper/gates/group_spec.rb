require 'helper'
require 'flipper/instrumentors/memory'

describe Flipper::Gates::Group do
  let(:adapter) { double('Adapter', :set_members => []) }
  let(:feature) { double('Feature', :name => :search, :adapter => adapter) }
  let(:instrumentor) { Flipper::Instrumentors::Memory.new }

  subject {
    described_class.new(feature, :instrumentor => instrumentor)
  }

  describe "instrumentation" do
    it "is recorded for open" do
      thing = Struct.new(:flipper_id).new('22')
      subject.open?(thing)

      event = instrumentor.events.last
      event.should_not be_nil
      event.name.should eq('open.group.gate.flipper')
      event.payload.should eq({
        :thing => thing,
      })
    end
  end

  describe "#description" do
    context "with groups in set" do
      before do
        adapter.stub(:set_members => Set['bacon', 'ham'])
      end

      it "returns Enabled" do
        subject.description.should eq("groups (bacon, ham)")
      end
    end

    context "with no groups in set" do
      before do
        adapter.stub(:set_members => Set.new)
      end

      it "returns Disabled" do
        subject.description.should eq('Disabled')
      end
    end
  end
end
