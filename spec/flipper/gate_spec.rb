require 'helper'

describe Flipper::Gate do
  let(:feature_name) { :stats }

  subject {
    described_class.new(feature_name)
  }

  describe "#initialize" do
    it "sets feature_name" do
      gate = described_class.new(feature_name)
      gate.feature_name.should be(feature_name)
    end
  end

  describe "#inspect" do
    it "returns easy to read string representation" do
      string = subject.inspect
      string.should include('Flipper::Gate')
      string.should include('feature_name=:stats')
    end
  end
end
