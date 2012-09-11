require 'helper'
require 'flipper/feature'
require 'flipper/adapters/memory'

describe Flipper::Feature do
  subject           { described_class.new(:search, adapter) }

  let(:source)      { {} }
  let(:adapter)     { Flipper::Adapters::Memory.new(source) }

  let(:admin_group) { Flipper.group(:admins) }
  let(:dev_group)   { Flipper.group(:devs) }

  let(:admin_thing) { double 'Non Flipper Thing', :identifier => 1,  :admin? => true, :dev? => false }
  let(:dev_thing)   { double 'Non Flipper Thing', :identifier => 10, :admin? => false, :dev? => true }

  let(:pitt)        { Flipper::Types::Actor.new(1) }
  let(:clooney)     { Flipper::Types::Actor.new(10) }

  let(:five_percent_of_actors) { Flipper::Types::PercentageOfActors.new(5) }
  let(:five_percent_of_random) { Flipper::Types::PercentageOfRandom.new(5) }

  before do
    Flipper.register(:admins) { |thing| thing.admin? }
    Flipper.register(:devs)   { |thing| thing.dev? }
  end

  def enable_feature(feature)
    key = Flipper::Key.new(subject.name, Flipper::Gates::Boolean::Key)
    adapter.write key, true
  end

  def enable_group(group)
    key = Flipper::Key.new(subject.name, Flipper::Gates::Group::Key)
    name = group.respond_to?(:name) ? group.name : group
    adapter.set_add key, name
  end

  def enable_actor(actor)
    key = Flipper::Key.new(subject.name, Flipper::Gates::Actor::Key)
    adapter.set_add key, actor.identifier
  end

  def enable_percentage_of_actors(percentage)
    key = Flipper::Key.new(subject.name, Flipper::Gates::PercentageOfActors::Key)
    adapter.write key, percentage.value
  end

  def enable_percentage_of_random(percentage)
    key = Flipper::Key.new(subject.name, Flipper::Gates::PercentageOfRandom::Key)
    adapter.write key, percentage.value
  end

  it "initializes with name and adapter" do
    feature = described_class.new(:search, adapter)
    feature.name.should eq(:search)
    feature.adapter.should eq(Flipper::Adapter.wrap(adapter))
  end

  describe "#gates" do
    it "returns array of gates" do
      subject.gates.should be_instance_of(Array)
      subject.gates.each do |gate|
        gate.should be_a(Flipper::Gate)
      end
      subject.gates.size.should be(5)
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

      it "adds feature to set of features" do
        adapter.set_members('features').should include(:search)
      end
    end

    context "with a group" do
      before do
        subject.enable(admin_group)
      end

      it "enables feature for non flipper thing in group" do
        subject.enabled?(admin_thing).should be_true
      end

      it "does not enable feature for non flipper thing in other group" do
        subject.enabled?(dev_thing).should be_false
      end

      it "enables feature for flipper actor in group" do
        subject.enabled?(Flipper::Types::Actor.new(admin_thing)).should be_true
      end

      it "does not enable for flipper actor not in group" do
        subject.enabled?(Flipper::Types::Actor.new(dev_thing)).should be_false
      end

      it "does not enable feature for all" do
        subject.enabled?.should be_false
      end

      it "adds feature to set of features" do
        adapter.set_members('features').should include(:search)
      end
    end

    context "with an actor" do
      before do
        subject.enable(pitt)
      end

      it "enables feature for actor" do
        subject.enabled?(pitt).should be_true
      end

      it "does not enable feature for other actors" do
        subject.enabled?(clooney).should be_false
      end

      it "adds feature to set of features" do
        adapter.set_members('features').should include(:search)
      end
    end

    context "with a percentage of actors" do
      before do
        subject.enable(five_percent_of_actors)
      end

      it "enables feature for actor within percentage" do
        subject.enabled?(pitt).should be_true
      end

      it "does not enable feature for actors not within percentage" do
        subject.enabled?(clooney).should be_false
      end

      it "adds feature to set of features" do
        adapter.set_members('features').should include(:search)
      end
    end

    context "with a percentage of random" do
      before do
        @gate = Flipper::Gates::PercentageOfRandom.new(subject)
        Flipper::Gates::PercentageOfRandom.should_receive(:new).and_return(@gate)
        subject.enable(five_percent_of_random)
      end

      it "enables feature for time within percentage" do
        @gate.stub(:rand => 0.04)
        subject.enabled?.should be_true
      end

      it "does not enable feature for time not within percentage" do
        @gate.stub(:rand => 0.10)
        subject.enabled?.should be_false
      end

      it "adds feature to set of features" do
        adapter.set_members('features').should include(:search)
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
        # ensures that random gate is stubbed with result that would be true for pitt
        @gate = Flipper::Gates::PercentageOfRandom.new(subject)
        @gate.stub(:rand => 0.04)
        Flipper::Gates::PercentageOfRandom.should_receive(:new).and_return(@gate)
        enable_group admin_group
        enable_actor pitt
        enable_percentage_of_actors five_percent_of_actors
        enable_percentage_of_random five_percent_of_random
        subject.disable
      end

      it "disables feature" do
        subject.enabled?.should be_false
      end

      it "disables for individual actor" do
        subject.enabled?(pitt).should be_false
      end

      it "disables actor in group" do
        subject.enabled?(admin_thing).should be_false
      end

      it "disables actor in percentage of actors" do
        subject.enabled?(pitt).should be_false
      end

      it "disables percentage of random" do
        subject.enabled?(pitt).should be_false
      end

      it "adds feature to set of features" do
        adapter.set_members('features').should include(:search)
      end
    end

    context "with a group" do
      before do
        enable_group dev_group
        enable_group admin_group
        subject.disable(admin_group)
      end

      it "disables the feature for non flipper thing in the group" do
        subject.enabled?(admin_thing).should be_false
      end

      it "does not disable feature for non flipper thing in other groups" do
        subject.enabled?(dev_thing).should be_true
      end

      it "disables feature for flipper actor in group" do
        subject.enabled?(Flipper::Types::Actor.new(admin_thing)).should be_false
      end

      it "does not disable feature for flipper actor in other groups" do
        subject.enabled?(Flipper::Types::Actor.new(dev_thing)).should be_true
      end

      it "adds feature to set of features" do
        adapter.set_members('features').should include(:search)
      end
    end

    context "with an actor" do
      before do
        enable_actor pitt
        enable_actor clooney
        subject.disable(pitt)
      end

      it "disables feature for actor" do
        subject.enabled?(pitt).should be_false
      end

      it "does not disable feature for other actors" do
        subject.enabled?(clooney).should be_true
      end

      it "adds feature to set of features" do
        adapter.set_members('features').should include(:search)
      end
    end

    context "with a percentage of actors" do
      before do
        subject.disable(five_percent_of_actors)
      end

      it "disables feature for actor within percentage" do
        subject.enabled?(pitt).should be_false
      end

      it "disables feature for actors not within percentage" do
        subject.enabled?(clooney).should be_false
      end

      it "adds feature to set of features" do
        adapter.set_members('features').should include(:search)
      end
    end

    context "with a percentage of time" do
      before do
        @gate = Flipper::Gates::PercentageOfRandom.new(subject)
        Flipper::Gates::PercentageOfRandom.should_receive(:new).and_return(@gate)
        subject.disable(five_percent_of_random)
      end

      it "disables feature for time within percentage" do
        @gate.stub(:rand => 0.04)
        subject.enabled?.should be_false
      end

      it "disables feature for time not within percentage" do
        @gate.stub(:rand => 0.10)
        subject.enabled?.should be_false
      end

      it "adds feature to set of features" do
        adapter.set_members('features').should include(:search)
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

    context "with no arguments, but boolean enabled" do
      before do
        enable_feature subject
      end

      it "returns true" do
        subject.enabled?.should be_true
      end
    end

    context "for actor in enabled group" do
      before do
        enable_group admin_group
      end

      it "returns true" do
        subject.enabled?(Flipper::Types::Actor.new(admin_thing)).should be_true
      end
    end

    context "for actor in disabled group" do
      it "returns false" do
        subject.enabled?(Flipper::Types::Actor.new(dev_thing)).should be_false
      end
    end

    context "for enabled actor" do
      before do
        enable_actor pitt
      end

      it "returns true" do
        subject.enabled?(pitt).should be_true
      end
    end

    context "for not enabled actor" do
      it "returns false" do
        subject.enabled?(clooney).should be_false
      end

      it "returns true if boolean enabled" do
        enable_feature subject
        subject.enabled?(clooney).should be_true
      end
    end

    context "for actor in percentage of actors enabled" do
      before do
        enable_percentage_of_actors five_percent_of_actors
      end

      it "returns true" do
        subject.enabled?(pitt).should be_true
      end
    end

    context "for actor not in percentage of actors enabled" do
      before do
        enable_percentage_of_actors five_percent_of_actors
      end

      it "returns false" do
        subject.enabled?(clooney).should be_false
      end

      it "returns true if boolean enabled" do
        enable_feature subject
        subject.enabled?(clooney).should be_true
      end
    end

    context "during enabled percentage of time" do
      before do
        @gate = Flipper::Gates::PercentageOfRandom.new(subject)
        @gate.stub(:rand => 0.04)
        Flipper::Gates::PercentageOfRandom.should_receive(:new).and_return(@gate)
        enable_percentage_of_random five_percent_of_random
      end

      it "returns true" do
        subject.enabled?.should be_true
        subject.enabled?(nil).should be_true
        subject.enabled?(pitt).should be_true
        subject.enabled?(admin_thing).should be_true
      end
    end

    context "during not enabled percentage of time" do
      before do
        @gate = Flipper::Gates::PercentageOfRandom.new(subject)
        @gate.stub(:rand => 0.10)
        Flipper::Gates::PercentageOfRandom.should_receive(:new).and_return(@gate)
        enable_percentage_of_random five_percent_of_random
      end

      it "returns false" do
        subject.enabled?.should be_false
        subject.enabled?(nil).should be_false
        subject.enabled?(pitt).should be_false
        subject.enabled?(admin_thing).should be_false
      end

      it "returns true if boolean enabled" do
        enable_feature subject
        subject.enabled?.should be_true
        subject.enabled?(nil).should be_true
        subject.enabled?(pitt).should be_true
        subject.enabled?(admin_thing).should be_true
      end
    end

    context "for a non flipper thing" do
      before do
        enable_group admin_group
      end

      it "returns true if in enabled group" do
        subject.enabled?(admin_thing).should be_true
      end

      it "returns false if not in enabled group" do
        subject.enabled?(dev_thing).should be_false
      end

      it "returns true if boolean enabled" do
        enable_feature subject
        subject.enabled?(admin_thing).should be_true
        subject.enabled?(dev_thing).should be_true
      end
    end

    context "for a non flipper thing that does not respond to something in group block" do
      let(:actor) { double('Actor') }

      before do
        boomboom = Flipper.register(:boomboom) { |actor| actor.boomboom? }
        enable_group boomboom
      end

      it "returns false" do
        expect { subject.enabled?(actor) }.to raise_error
      end
    end

    context "for a non flipper thing when group in adapter, but not defined in code" do
      let(:actor) { double('Actor') }

      before do
        enable_group :support
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

    it "enables feature for object in enabled group" do
      subject.enabled?(admin_thing).should be_true
    end

    it "does not enable feature for object in not enabled group" do
      subject.enabled?(dev_thing).should be_false
    end
  end
end
