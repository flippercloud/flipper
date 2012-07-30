require 'helper'
require 'flipper/types/group'

describe Flipper::Types::Group do
  subject do
    Flipper::Types::Group.new(:admins) { |actor| actor.admin? }
  end

  it "is enumerable at the class level" do
    Flipper::Types::Group.define(:admins) { |actor| actor.admin? }
    Flipper::Types::Group.map { |group|
      group.name
    }.should eq([:admins])
  end

  describe ".all" do
    it "defaults to empty array" do
      Flipper::Types::Group.all.should eq([])
    end
  end

  describe ".define" do
    before do
      @result = Flipper::Types::Group.define(:admins) { |actor| actor.admin? }
    end

    it "adds group to all" do
      Flipper::Types::Group.all.should include(@result)
    end
  end

  describe ".get" do
    it "returns nil if group does not exist" do
      Flipper::Types::Group.get(:not_found).should be_nil
    end

    it "returns group if group exists" do
      group = Flipper::Types::Group.define(:admins) { |actor| actor.admin? }
      Flipper::Types::Group.get(:admins).should eq(group)
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
      subject.match?(admin_actor).should be_true
    end

    it "returns false if block does not match" do
      subject.match?(non_admin_actor).should be_false
    end
  end
end
