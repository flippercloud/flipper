require 'helper'

describe Flipper::Gates::Boolean do
  let(:feature_name) { :search }

  subject {
    described_class.new
  }

  def context(bool)
    Flipper::GateContext.new(
      gates: [],
      values: Flipper::GateValues.new({boolean: bool}),
      feature_name: feature_name
    )
  end

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
        subject.open?(Object.new, context(true)).should eq(true)
      end
    end

    context "for false value" do
      it "returns false" do
        subject.open?(Object.new, context(false)).should eq(false)
      end
    end
  end

  describe "#protects?" do
    it "returns true for boolean type" do
      subject.protects?(Flipper::Types::Boolean.new(true)).should be(true)
    end

    it "returns true for true" do
      subject.protects?(true).should be(true)
    end

    it "returns true for false" do
      subject.protects?(false).should be(true)
    end
  end

  describe "#wrap" do
    it "returns boolean type for boolean type" do
      subject.wrap(Flipper::Types::Boolean.new(true)).should be_instance_of(Flipper::Types::Boolean)
    end

    it "returns boolean type for true" do
      subject.wrap(true).should be_instance_of(Flipper::Types::Boolean)
      subject.wrap(true).value.should be(true)
    end

    it "returns boolean type for true" do
      subject.wrap(false).should be_instance_of(Flipper::Types::Boolean)
      subject.wrap(false).value.should be(false)
    end
  end
end
