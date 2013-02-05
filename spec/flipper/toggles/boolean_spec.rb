require 'helper'

describe Flipper::Toggles::Boolean do
  let(:key) { double('Key') }
  let(:adapter) { double('Adapter', :read => true) }
  let(:gate) { double('Gate', :adapter => adapter, :key => key, :adapter_key => 'foo') }

  subject {
    described_class.new(gate)
  }

  describe "#value" do
    described_class::TruthMap.each do |value, expected|
      context "when adapter value set to #{value.inspect}" do
        it "returns #{expected.inspect}" do
          adapter.stub(:read => value)
          subject.value.should be(expected)
        end
      end
    end

    context "for value not in truth map" do
      it "returns false" do
        adapter.stub(:read => 'jibberish')
        subject.value.should be(false)
      end
    end
  end

  describe "#enabled?" do
    described_class::TruthMap.each do |value, expected|
      context "when adapter value set to #{value.inspect}" do
        it "returns #{expected.inspect}" do
          adapter.stub(:read => value)
          subject.enabled?.should be(expected)
        end
      end
    end
  end
end
