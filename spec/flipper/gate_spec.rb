require 'helper'

describe Flipper::Gate do
  let(:adapter) { double('Adapter', :name => 'memory', :read => '22') }
  let(:feature) { double('Feature', :name => :search, :adapter => adapter) }

  subject {
    described_class.new(feature)
  }

  describe "#initialize" do
    it "sets feature" do
      gate = described_class.new(feature)
      gate.feature.should be(feature)
    end

    it "defaults instrumenter" do
      gate = described_class.new(feature)
      gate.instrumenter.should be(Flipper::Instrumenters::Noop)
    end

    it "allows overriding instrumenter" do
      instrumenter = double('Instrumentor')
      gate = described_class.new(feature, :instrumenter => instrumenter)
      gate.instrumenter.should be(instrumenter)
    end
  end

  describe "#inspect" do
    it "returns easy to read string representation" do
      subject.stub(:value => 22)
      string = subject.inspect
      string.should include('Flipper::Gate')
      string.should include('feature=:search')
    end
  end
end
