require 'helper'

describe Flipper::Toggles::Value do
  let(:key) { double('Key') }
  let(:adapter) { double('Adapter', :read => '22') }
  let(:gate) { double('Gate', :adapter => adapter, :key => key) }

  subject {
    toggle = described_class.new(gate)
    toggle.stub(:value => 22)
    toggle
  }

  describe "#enabled?" do
    context "for nil value" do
      before do
        subject.stub(:value => nil)
      end

      it "returns false" do
        subject.enabled?.should be_false
      end
    end

    context "for integer" do
      before do
        subject.stub(:value => 22)
      end

      it "returns true" do
        subject.enabled?.should be_true
      end
    end

    context "for string integer" do
      before do
        subject.stub(:value => '22')
      end

      it "returns true" do
        subject.enabled?.should be_true
      end
    end

    context "for zero" do
      before do
        subject.stub(:value => 0)
      end

      it "returns false" do
        subject.enabled?.should be_false
      end
    end
  end
end
