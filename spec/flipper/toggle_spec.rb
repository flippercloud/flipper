require 'helper'

describe Flipper::Toggle do
  let(:key) { double('Key') }
  let(:adapter) { double('Adapter', :read => '22') }
  let(:gate) { double('Gate', :adapter => adapter, :key => key) }

  subject {
    toggle = Flipper::Toggle.new(gate)
    toggle.stub(:value => '22') # implemented in subclass
    toggle
  }

  describe "#inspect" do
    it "returns easy to read string representation" do
      string = subject.inspect
      string.should match(/Flipper::Toggle/)
      string.should match(/gate=/)
      string.should match(/value=22/)
    end
  end
end
