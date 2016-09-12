require 'helper'
require 'flipper/types/group'

RSpec.describe Flipper::Types::Group do
  subject do
    Flipper.register(:admins) { |actor| actor.admin? }
  end

  describe ".wrap" do
    context "with group instance" do
      it "returns group instance" do
        expect(described_class.wrap(subject)).to eq(subject)
      end
    end

    context "with Symbol group name" do
      it "returns group instance" do
        expect(described_class.wrap(subject.name)).to eq(subject)
      end
    end

    context "with String group name" do
      it "returns group instance" do
        expect(described_class.wrap(subject.name.to_s)).to eq(subject)
      end
    end
  end

  it "initializes with name" do
    group = Flipper::Types::Group.new(:admins)
    expect(group).to be_instance_of(Flipper::Types::Group)
  end

  describe "#name" do
    it "returns name" do
      expect(subject.name).to eq(:admins)
    end
  end

  describe "#match?" do
    let(:admin_actor) { double('Actor', :admin? => true) }
    let(:non_admin_actor) { double('Actor', :admin? => false) }

    it "returns true if block matches" do
      expect(subject.match?(admin_actor)).to eq(true)
    end

    it "returns false if block does not match" do
      expect(subject.match?(non_admin_actor)).to eq(false)
    end

    it "returns true for truthy block results" do
      group = Flipper::Types::Group.new(:examples) do |actor|
        actor.email =~ /@example\.com/
      end
      expect(group.match?(double('Actor', :email => "foo@example.com"))).to be_truthy
    end

    it "returns false for falsey block results" do
      group = Flipper::Types::Group.new(:examples) do |actor|
        nil
      end
      expect(group.match?(double('Actor'))).to be_falsey
    end
  end
end
