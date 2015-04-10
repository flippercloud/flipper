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

    it "raises an error when the group has not been registered" do
      expect {
        described_class.wrap(:early_access)
      }.to raise_error(Flipper::GroupNotRegistered)
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
end
