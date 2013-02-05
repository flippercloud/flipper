require 'helper'

describe Flipper::Gate do
  let(:adapter) { double('Adapter', :name => 'memory', :read => '22') }
  let(:feature) { double('Feature', :name => :search, :adapter => adapter) }

  subject {
    gate = described_class.new(feature)
    # implemented in subclass
    gate.stub({
      :key => :actors,
      :description => 'enabled',
    })
    gate
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
      string = subject.inspect
      string.should include('Flipper::Gate')
      string.should include('feature=:search')
      string.should include('description="enabled"')
      string.should include("adapter=#{subject.adapter.name.inspect}")
      string.should include('adapter_key=#<Flipper::Key:')
      string.should include('toggle_class=Flipper::Toggles::Value')
      string.should include('toggle_value="22"')
    end
  end
end
