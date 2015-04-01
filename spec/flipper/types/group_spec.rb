require 'helper'
require 'flipper/types/group'

describe Flipper::Types::Group do
  subject do
    Flipper.register(:admins) { |actor| actor.admin? }
  end

  describe ".wrap" do
    context "with group instance" do
      it "returns group instance" do
        described_class.wrap(subject).should eq(subject)
      end
    end

    context "with Symbol group name" do
      it "returns group instance" do
        described_class.wrap(subject.name).should eq(subject)
      end
    end

    context "with String group name" do
      it "returns group instance" do
        described_class.wrap(subject.name.to_s).should eq(subject)
      end
    end
  end

  it "initializes with name" do
    group = Flipper::Types::Group.new(:admins)
    group.should be_instance_of(Flipper::Types::Group)
  end

  describe "#name" do
    it "returns name" do
      subject.name.should eq(:admins)
    end
  end

  describe "#match?" do
    let(:admin_actor) { double('Actor', :admin? => true) }
    let(:non_admin_actor) { double('Actor', :admin? => false) }

    it "returns true if block matches" do
      subject.match?(admin_actor).should eq(true)
    end

    it "returns false if block does not match" do
      subject.match?(non_admin_actor).should eq(false)
    end
  end
end
