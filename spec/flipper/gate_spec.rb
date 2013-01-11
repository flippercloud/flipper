require 'helper'

describe Flipper::Gate do
  let(:adapter) { double('Adapter', :name => 'memory', :read => '22') }
  let(:feature) { double('Feature', :name => :search, :adapter => adapter) }

  subject {
    gate = described_class.new(feature)
    gate.stub(:type_key => :actors) # implemented in subclass
    gate
  }

  describe "#inspect" do
    it "returns easy to read string representation" do
      string = subject.inspect
      string.should include('Flipper::Gate')
      string.should include('feature=:search')
      string.should include('adapter="memory"')
      string.should include('toggle_class=Flipper::Toggles::Value')
      string.should include('toggle_value="22"')
      string.should include('key=#<Flipper::Key:')
    end
  end
end
