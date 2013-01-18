require 'helper'

describe Flipper::Toggles::Boolean do
  let(:key) { double('Key') }
  let(:adapter) { double('Adapter', :read => '22') }
  let(:gate) { double('Gate', :adapter => adapter, :key => key) }

  subject {
    toggle = described_class.new(gate)
    toggle.stub(:value => 22)
    toggle
  }

  describe "#enabled?" do
    context "for nil" do
      before do
        subject.stub(:value => nil)
      end

      it "returns false" do
        subject.enabled?.should be_false
      end
    end

    context "for false" do
      before do
        subject.stub(:value => false)
      end

      it "returns false" do
        subject.enabled?.should be_false
      end
    end

    context "for true" do
      before do
        subject.stub(:value => true)
      end

      it "returns true" do
        subject.enabled?.should be_true
      end
    end
  end
end
