require 'helper'
require 'flipper/feature'
require 'flipper/adapters/memory'

describe Flipper::Feature do
  subject           { Flipper::Feature.new(:search, adapter) }

  let(:adapter)     { Flipper::Adapters::Memory.new }

  let(:admin_group) { Flipper::Group.get(:admins) }
  let(:dev_group)   { Flipper::Group.get(:devs) }

  let(:admin_actor) { double 'Actor', :admin? => true, :dev? => false }
  let(:dev_actor)   { double 'Actor', :admin? => false, :dev? => true }

  before do
    Flipper::Group.all.clear

    Flipper::Group.define(:admins) { |actor| actor.admin? }
    Flipper::Group.define(:devs)   { |actor| actor.dev? }

    adapter.clear
  end

  it "initializes with name and adapter" do
    feature = Flipper::Feature.new(:search, adapter)
    feature.should be_instance_of(Flipper::Feature)
  end

  describe "#name" do
    it "returns name" do
      subject.name.should eq(:search)
    end
  end

  describe "#adapter" do
    it "returns adapter" do
      subject.adapter.should eq(adapter)
    end
  end

  describe "#enable" do
    context "with no arguments" do
      before do
        subject.enable
      end

      it "enables feature for all" do
        subject.enabled?.should be_true
      end
    end

    context "with a group" do
      before do
        subject.enable(admin_group)
      end

      it "enables feature for actor in group" do
        subject.enabled?(admin_actor).should be_true
      end

      it "does not enable feature for actor in other group" do
        subject.enabled?(dev_actor).should be_false
      end

      it "does not enable feature for all" do
        subject.enabled?.should be_false
      end
    end

    context "with argument that has no gate" do
      it "raises error" do
        thing = Object.new
        expect {
          subject.enable(thing)
        }.to raise_error(Flipper::GateNotFound, "Could not find gate for #{thing.inspect}")
      end
    end
  end

  describe "#disable" do
    context "with no arguments" do
      before do
        adapter.set_add("#{subject.name}.#{Flipper::Gates::Group::Key}", admin_group.name)
        subject.disable
      end

      it "disables feature" do
        subject.enabled?.should be_false
      end

      it "disables feature for actors in previously enabled groups" do
        subject.enabled?(admin_actor).should be_false
      end
    end

    context "with a group" do
      before do
        adapter.set_add("#{subject.name}.#{Flipper::Gates::Group::Key}", dev_group.name)
        subject.disable(admin_group)
      end

      it "disables the feature for an actor in the group" do
        subject.enabled?(admin_actor).should be_false
      end

      it "does not disable feature for actor in other groups" do
        subject.enabled?(dev_actor).should be_true
      end
    end

    context "with argument that has no gate" do
      it "raises error" do
        thing = Object.new
        expect {
          subject.disable(thing)
        }.to raise_error(Flipper::GateNotFound, "Could not find gate for #{thing.inspect}")
      end
    end
  end

  describe "#enabled?" do
    context "with no arguments" do
      it "defaults to false" do
        subject.enabled?.should be_false
      end
    end

    context "for an actor" do
      before do
        adapter.set_add("#{subject.name}.#{Flipper::Gates::Group::Key}", admin_group.name)
      end

      it "returns true if in enabled group" do
        subject.enabled?(admin_actor).should be_true
      end

      it "returns false if not in enabled group" do
        subject.enabled?(dev_actor).should be_false
      end

      it "returns true if switch enabled" do
        adapter.write("#{subject.name}.#{Flipper::Gates::Boolean::Key}", true)
        subject.enabled?(admin_actor).should be_true
        subject.enabled?(dev_actor).should be_true
      end
    end

    context "for an actor that does not respond to something in group block" do
      let(:actor) { double('Actor') }

      before do
        adapter.set_add("#{subject.name}.#{Flipper::Gates::Group::Key}", admin_group.name)
      end

      it "returns false" do
        expect { subject.enabled?(actor) }.to raise_error
      end
    end

    context "for an actor when group not defined" do
      let(:actor) { double('Actor') }

      before do
        adapter.set_add("#{subject.name}.#{Flipper::Gates::Group::Key}", :support)
      end

      it "returns false" do
        subject.enabled?(actor).should be_false
      end
    end
  end

  context "#disabled?" do
    it "returns the opposite of enabled" do
      subject.stub(:enabled? => true)
      subject.disabled?.should be_false

      subject.stub(:enabled? => false)
      subject.disabled?.should be_true
    end
  end

  context "enabling multiple groups, disabling everything, then enabling one group" do
    before do
      subject.enable(admin_group)
      subject.enable(dev_group)
      subject.disable
      subject.enable(admin_group)
    end

    it "enables feature for actor in enabled group" do
      pending
      subject.enabled?(admin_actor).should be_true
    end

    it "does not enable feature for actor in disabled group" do
      pending
      subject.enabled?(dev_actor).should be_false
    end
  end
end
