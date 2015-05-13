require 'helper'

describe Flipper::Gates::Group do
  let(:feature_name) { :search }

  subject {
    described_class.new
  }

  describe "#open?" do
    context "with a group in adapter, but not registered" do
      before do
        Flipper.register(:staff) { |thing| true }
      end

      it "ignores group" do
        thing = Struct.new(:flipper_id).new('5')
        subject.open?(thing, Set[:newbs, :staff], feature_name: feature_name).should eq(true)
      end
    end

    context "thing that does not respond to method in group block" do
      before do
        Flipper.register(:stinkers) { |thing| thing.stinker? }
      end

      it "raises error" do
        expect {
          subject.open?(Object.new, Set[:stinkers], feature_name: feature_name)
        }.to raise_error(NoMethodError)
      end
    end
  end

  describe "#wrap" do
    it "returns group instance for symbol" do
      group = Flipper.register(:admins) {}
      subject.wrap(:admins).should eq(group)
    end

    it "returns group instance for group instance" do
      group = Flipper.register(:admins) {}
      subject.wrap(group).should eq(group)
    end
  end

  describe "#protects?" do
    it "returns true for group" do
      group = Flipper.register(:admins) {}
      subject.protects?(group).should be(true)
    end

    it "returns true for symbol" do
      subject.protects?(:admins).should be(true)
    end
  end
end
