require 'helper'

describe Flipper::Gate do
  let(:adapter) { double('Adapter', :name => 'memory', :read => '22') }
  let(:feature) { double('Feature', :name => :search, :adapter => adapter) }

  subject {
    gate = described_class.new(feature)
    gate.stub(:key => :actors) # implemented in subclass
    gate
  }

  describe "#initialize" do
    it "sets feature" do
      gate = described_class.new(feature)
      gate.feature.should be(feature)
    end

    it "defaults instrumentor" do
      gate = described_class.new(feature)
      gate.instrumentor.should be(Flipper::Instrumentors::Noop)
    end

    it "allows overriding instrumentor" do
      instrumentor = double('Instrumentor')
      gate = described_class.new(feature, :instrumentor => instrumentor)
      gate.instrumentor.should be(instrumentor)
    end
  end

  describe "#inspect" do
    it "returns easy to read string representation" do
      string = subject.inspect
      string.should include('Flipper::Gate')
      string.should include('feature=:search')
      string.should include('adapter="memory"')
      string.should include('toggle_class=Flipper::Toggles::Value')
      string.should include('toggle_value="22"')
      string.should include('adapter_key=#<Flipper::Key:')
    end
  end
end
