require 'helper'

describe Flipper::Toggles::Set do
  let(:key) { double('Key') }
  let(:adapter) { double('Adapter', :read => '22') }
  let(:gate) { double('Gate', :adapter => adapter, :key => key) }

  subject {
    toggle = described_class.new(gate)
    toggle.stub(:value => Set['bacon']) # implemented in subclass
    toggle
  }

  describe "#enabled?" do
    context "for empty set" do
      before do
        subject.stub(:value => Set.new)
      end

      it "returns false" do
        subject.enabled?.should be_false
      end
    end

    context "for non-empty set" do
      before do
        subject.stub(:value => Set['bacon'])
      end

      it "returns true" do
        subject.enabled?.should be_true
      end
    end
  end
end
