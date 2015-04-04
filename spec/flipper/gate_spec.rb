require 'helper'

describe Flipper::Gate do
  let(:feature_name) { :stats }

  subject {
    described_class.new
  }

  describe "#inspect" do
    it "returns easy to read string representation" do
      string = subject.inspect
      string.should include('Flipper::Gate')
    end
  end
end
