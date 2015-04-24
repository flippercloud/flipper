require 'helper'

describe Flipper::Gates::Boolean do
  let(:feature_name) { :search }

  subject {
    described_class.new
  }

  describe "#enabled?" do
    context "for true value" do
      it "returns true" do
        subject.enabled?(true).should eq(true)
      end
    end

    context "for false value" do
      it "returns false" do
        subject.enabled?(false).should eq(false)
      end
    end
  end

  describe "#open?" do
    context "for true value" do
      it "returns true" do
        subject.open?(Object.new, true, feature_name: feature_name).should eq(true)
      end
    end

    context "for false value" do
      it "returns false" do
        subject.open?(Object.new, false, feature_name: feature_name).should eq(false)
      end
    end
  end
end
