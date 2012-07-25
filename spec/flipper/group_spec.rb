require 'helper'
require 'flipper/group'

describe Flipper::Group do
  subject do
    Flipper::Group.new(:admins) { |actor| actor.admin? }
  end

  before do
    Flipper::Group.all.clear
  end

  it "is enumerable at the class level" do
    Flipper::Group.define(:admins) { |actor| actor.admin? }
    Flipper::Group.map { |group|
      group.name
    }.should eq([:admins])
  end

  describe ".all" do
    it "defaults to empty array" do
      Flipper::Group.all.should eq([])
    end
  end

  describe ".define" do
    before do
      @result = Flipper::Group.define(:admins) { |actor| actor.admin? }
    end

    it "adds group to all" do
      Flipper::Group.all.should include(@result)
    end
  end

  describe ".get" do
    it "returns nil if group does not exist" do
      Flipper::Group.get(:not_found).should be_nil
    end

    it "returns group if group exists" do
      group = Flipper::Group.define(:admins) { |actor| actor.admin? }
      Flipper::Group.get(:admins).should eq(group)
    end
  end

  it "initializes with name" do
    group = Flipper::Group.new(:admins)
    group.should be_instance_of(Flipper::Group)
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
