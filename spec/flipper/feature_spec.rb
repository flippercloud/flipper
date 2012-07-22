require 'helper'
require 'flipper/feature'

describe Flipper::Feature do
  subject do
    Flipper::Feature.new(:search)
  end

  it "initializes with name" do
    feature = Flipper::Feature.new(:search)
    feature.should be_instance_of(Flipper::Feature)
  end

  describe "#enabled?" do
    it "defaults to false" do
      feature = Flipper::Feature.new(:search)
      feature.enabled?.should be_false
    end
  end

  describe "#enable" do
    before do
      subject.enable
    end

    it "is enabled" do
      subject.enabled?.should be_true
    end

    it "is not disabled" do
      subject.disabled?.should be_false
    end
  end

  describe "#disable" do
    before do
      subject.disable
    end

    it "is not enabled" do
      subject.enabled?.should be_false
    end

    it "is disabled" do
      subject.disabled?.should be_true
    end
  end
end
