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

    it "defaults instrumenter" do
      gate = described_class.new(feature_name)
      gate.instrumenter.should be(Flipper::Instrumenters::Noop)
    end

    it "allows overriding instrumenter" do
      instrumenter = double('Instrumentor')
      gate = described_class.new(feature_name, :instrumenter => instrumenter)
      gate.instrumenter.should be(instrumenter)
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
