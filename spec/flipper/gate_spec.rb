require 'helper'

describe Flipper::Gate do
  let(:feature_name) { :stats }

  subject {
    described_class.new
  }

  describe "#initialize" do
    it "defaults instrumenter" do
      gate = described_class.new
      gate.instrumenter.should be(Flipper::Instrumenters::Noop)
    end

    it "allows overriding instrumenter" do
      instrumenter = double('Instrumentor')
      gate = described_class.new(:instrumenter => instrumenter)
      gate.instrumenter.should be(instrumenter)
    end
  end

  describe "#inspect" do
    it "returns easy to read string representation" do
      string = subject.inspect
      string.should include('Flipper::Gate')
    end
  end
end
