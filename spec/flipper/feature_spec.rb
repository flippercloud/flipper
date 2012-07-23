require 'helper'
require 'flipper/feature'
require 'adapter/memory'

describe Flipper::Feature do
  subject {
    Flipper::Feature.new(:search, adapter)
  }

  let(:adapter) {
    Adapter[:memory].new({})
  }

  before do
    adapter.clear
  end

  it "initializes with name and adapter" do
    feature = Flipper::Feature.new(:search, adapter)
    feature.should be_instance_of(Flipper::Feature)
  end

  describe "#enabled?" do
    it "defaults to false" do
      subject.enabled?.should be_false
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
