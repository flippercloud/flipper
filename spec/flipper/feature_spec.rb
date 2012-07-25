require 'helper'
require 'flipper/feature'
require 'flipper/memory_adapter'

describe Flipper::Feature do
  subject { Flipper::Feature.new(:search, adapter) }

  let(:adapter)     { Flipper::MemoryAdapter.new }
  let(:admin_group) { Flipper::Group.get(:admins) }
  let(:dev_group)   { Flipper::Group.get(:devs) }

  before do
    Flipper::Group.all.clear

    Flipper::Group.define(:admins) { |actor| actor.admin? }
    Flipper::Group.define(:devs) { |actor| actor.dev? }

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

      it "enables feature for group" do
        subject.enabled?(admin_group).should be_true
      end

      it "does not enable feature for all" do
        subject.enabled?.should be_false
      end
    end
  end

  describe "#disable" do
    context "with no arguments" do
      before do
        adapter.set_add("#{subject.name}.groups", admin_group.name)
        subject.disable
      end

      it "disables feature" do
        subject.disabled?.should be_true
      end

      it "disables feature for all enabled groups" do
        subject.disabled?(admin_group).should be_true
      end
    end

    context "with a group" do
      before do
        adapter.set_add("#{subject.name}.groups", dev_group.name)
        subject.disable(admin_group)
      end

      it "disables the feature for the group" do
        subject.disabled?(admin_group).should be_true
      end

      it "does not disable feature for other groups" do
        subject.disabled?(dev_group).should be_false
      end
    end
  end

  describe "#enabled?" do
    context "with no arguments" do
      it "defaults to false" do
        subject.enabled?.should be_false
      end
    end

    context "for a group" do
      it "returns true if group enabled" do
        adapter.set_add("#{subject.name}.groups", admin_group.name)
        subject.enabled?(admin_group).should be_true
      end

      it "returns false if group not enabled" do
        subject.enabled?(admin_group).should be_false
      end

      it "returns true if switch enabled" do
        adapter.write("#{subject.name}.switch", true)
        subject.enabled?(admin_group).should be_true
      end
    end

    context "for an actor" do
      let(:admin_actor) { double('Actor', :admin? => true) }
      let(:non_admin_actor) { double('Actor', :admin? => false) }

      before do
        adapter.set_add("#{subject.name}.groups", admin_group.name)
      end

      it "returns true if in enabled group" do
        subject.enabled?(admin_actor).should be_true
      end

      it "returns false if not in enabled group" do
        subject.enabled?(non_admin_actor).should be_false
      end

      it "returns true if switch enabled" do
        adapter.write("#{subject.name}.switch", true)
        subject.enabled?(admin_actor).should be_true
        subject.enabled?(non_admin_actor).should be_true
      end
    end

    context "for an actor that does not respond to something in group block" do
      let(:actor) { double('Actor') }

      before do
        adapter.set_add("#{subject.name}.groups", admin_group.name)
      end

      it "returns false" do
        expect { subject.enabled?(actor) }.to raise_error
      end
    end

    context "for an actor when group not defined" do
      let(:actor) { double('Actor') }

      before do
        adapter.set_add("#{subject.name}.groups", :support)
      end

      it "does not raise error" do
        subject.enabled?(actor).should be_false
      end
    end
  end
end
