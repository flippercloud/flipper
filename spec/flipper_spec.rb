require 'helper'

describe Flipper do
  describe ".groups" do
    it "returns a registry instance" do
      Flipper.groups.should be_instance_of(Flipper::Registry)
    end
  end

  describe ".groups=" do
    it "sets groups registry" do
      registry = Flipper::Registry.new
      Flipper.groups = registry
      Flipper.instance_variable_get("@groups").should eq(registry)
    end
  end

  describe ".register" do
    it "adds a group to the group_registry" do
      group = Flipper.register(:admins) { |actor| actor.admin? }
      Flipper.groups.get(:admins).should eq(group)
    end

    it "raises exception if group already registered" do
      Flipper.register(:admins) { }

      expect {
        Flipper.register(:admins) { }
      }.to raise_error(Flipper::DuplicateGroup)
    end
  end

  describe ".group" do
    context "for registered group" do
      before do
        @group = Flipper.register(:admins) { }
      end

      it "returns group" do
        Flipper.group(:admins).should eq(@group)
      end
    end

    context "for unregistered group" do
      it "returns nil" do
        Flipper.group(:cats).should be_nil
      end
    end
  end
end
