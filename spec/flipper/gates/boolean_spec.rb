require 'helper'
require 'flipper/instrumenters/memory'

describe Flipper::Gates::Boolean do
  let(:instrumenter) { Flipper::Instrumenters::Memory.new }
  let(:feature_name) { :search }

  subject {
    described_class.new(feature_name, :instrumenter => instrumenter)
  }

  describe "#description" do
    context "for enabled" do
      it "returns Enabled" do
        subject.description(true).should eq('Enabled')
      end
    end

    context "for disabled" do
      it "returns Disabled" do
        subject.description(false).should eq('Disabled')
      end
    end
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

    context "for nil value" do
      it "returns false" do
        subject.enabled?(nil).should eq(false)
      end
    end

    context "for empty string value" do
      it "returns false" do
        subject.enabled?('').should eq(false)
      end
    end

    context "for the string true value" do
      it "returns true" do
        subject.enabled?('true').should eq(true)
      end
    end

    context "for the string false value" do
      it "returns false" do
        subject.enabled?('false').should eq(false)
      end
    end
  end

  describe "#open?" do
    context "for true value" do
      it "returns true" do
        subject.open?(Object.new, true).should eq(true)
      end
    end

    context "for false value" do
      it "returns false" do
        subject.open?(Object.new, false).should eq(false)
      end
    end

    context "for nil value" do
      it "returns false" do
        subject.open?(Object.new, nil).should eq(false)
      end
    end

    context "for string true value" do
      it "returns true" do
        subject.open?(Object.new, 'true').should eq(true)
      end
    end

    context "for string false value" do
      it "returns false" do
        subject.open?(Object.new, 'false').should eq(false)
      end
    end

    context "for an empty string value" do
      it "returns false" do
        subject.open?(Object.new, '').should eq(false)
      end
    end
  end
end
