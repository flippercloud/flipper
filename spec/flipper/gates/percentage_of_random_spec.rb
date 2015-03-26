require 'helper'
require 'flipper/instrumenters/memory'

describe Flipper::Gates::PercentageOfRandom do
  let(:instrumenter) { Flipper::Instrumenters::Memory.new }
  let(:feature_name) { :search }

  subject {
    described_class.new(feature_name, :instrumenter => instrumenter)
  }

  describe "#description" do
    context "when enabled" do
      it "returns text" do
        subject.description(22).should eq('22% of the time')
      end
    end

    context "when disabled" do
      it "returns disabled" do
        subject.description(nil).should eq('disabled')
        subject.description(0).should eq('disabled')
      end
    end
  end
end
