require 'helper'
require 'flipper/types/group'

describe Flipper::Types::Group do
  before do
    Flipper.register(:admins) { }
  end

  subject do
    Flipper::Types::Group.new(:admins)
  end

  describe ".wrap" do
    it "returns the group when passed a group" do
      described_class.wrap(subject).should eq(subject)
    end

    it "creates a group when passed a name" do
      described_class.wrap(:admins).should be_instance_of(described_class)
    end

    it "creates a group when passed a name and block parameter" do
      described_class.wrap(:admins, "5").should be_instance_of(described_class)
    end

    it "raises an error when the group has not been registered" do
      expect {
        described_class.wrap(:early_access)
      }.to raise_error(Flipper::GroupNotRegistered)
    end

    it "raises an error when passed a group and backing object" do
      expect {
        described_class.wrap(subject, "5")
      }.to raise_error(ArgumentError)
    end
  end

  describe ".dehydrate" do
    context "with a block parameter" do
      it "combines name and block parameter into a string" do
        described_class.dehydrate("admins", "5").should eq("admins\x1E5")
      end
    end

    context "without a block parameter" do
      it "returns the name" do
        described_class.dehydrate("admins", nil).should eq("admins")
      end
    end
  end

  describe ".hydrate" do
    context "with a block parameter" do
      it "returns the name and block parameter as strings" do
        described_class.hydrate("admins\x1E5").should eq(["admins", "5"])
      end
    end

    context "without a block parameter" do
      it "returns the name" do
        described_class.hydrate("admins").should eq(["admins"])
      end
    end

    context "when passed a symbol" do
      it "returns the name and block parameter as strings" do
        described_class.hydrate("admins\x1E5".to_sym).should eq(["admins", "5"])
      end
    end
  end

  it "initializes with name" do
    subject.should be_instance_of(Flipper::Types::Group)
  end

  it "raises an error when the group has not been registered" do
    expect {
      described_class.new(:early_access)
    }.to raise_error(Flipper::GroupNotRegistered)
  end

  context "with a block parameter" do
    subject { described_class.new(:admins, Struct.new(:to_str).new("5")) }

    it "combines name and object ID into the value" do
      subject.value.should eq("admins\x1E5")
    end

    it "raises an error if block parameter does not respond to to_str" do
      expect {
        described_class.new(:admins, Hash.new)
      }.to raise_error(ArgumentError)
    end
  end
end
