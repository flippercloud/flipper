require 'helper'
require 'flipper/feature'
require 'flipper/adapters/memory'

describe Flipper::Feature do
  subject           { described_class.new(:search, adapter) }

  let(:actor_class) { Struct.new(:flipper_id) }

  let(:source)      { {} }
  let(:adapter)     { Flipper::Adapters::Memory.new(source) }

  let(:admin_group) { Flipper.group(:admins) }
  let(:dev_group)   { Flipper.group(:devs) }

  let(:admin_thing) { double 'Non Flipper Thing', :flipper_id => 1,  :admin? => true, :dev? => false }
  let(:dev_thing)   { double 'Non Flipper Thing', :flipper_id => 10, :admin? => false, :dev? => true }

  let(:pitt)        { actor_class.new(1) }
  let(:clooney)     { actor_class.new(10) }

  let(:five_percent_of_actors) { Flipper::Types::PercentageOfActors.new(5) }
  let(:five_percent_of_random) { Flipper::Types::PercentageOfRandom.new(5) }

  before do
    Flipper.register(:admins) { |thing| thing.admin? }
    Flipper.register(:devs)   { |thing| thing.dev? }
  end

  after do
    Flipper.groups = nil
  end

  describe "#enable" do
    context "with no arguments" do
      before do
        @result = subject.enable
      end

      it "returns true" do
        @result.should be_true
      end

      it "enables feature for all" do
        subject.enabled?.should be_true
      end

      it "adds feature to set of features" do
        adapter.set_members('features').should include('search')
      end
    end

    context "with a group" do
      before do
        @result = subject.enable(admin_group)
      end

      it "returns true" do
        @result.should be_true
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
        adapter.set_members('features').should include('search')
      end
    end

    context "with an actor" do
      before do
        @result = subject.enable(pitt)
      end

      it "returns true" do
        @result.should be_true
      end

      it "enables feature for actor" do
        subject.enabled?(pitt).should be_true
      end

      it "does not enable feature for other actors" do
        subject.enabled?(clooney).should be_false
      end

      it "adds feature to set of features" do
        adapter.set_members('features').should include('search')
      end
    end

    context "with a percentage of actors" do
      before do
        @result = subject.enable(five_percent_of_actors)
      end

      it "returns true" do
        @result.should be_true
      end

      it "enables feature for actor within percentage" do
        enabled = (1..100).select { |i|
          thing = actor_class.new(i)
          subject.enabled?(thing)
        }.size

        enabled.should be_within(2).of(5)
      end

      it "adds feature to set of features" do
        adapter.set_members('features').should include('search')
      end
    end

    context "with a percentage of random" do
      before do
        @gate = Flipper::Gates::PercentageOfRandom.new(subject)
        Flipper::Gates::PercentageOfRandom.should_receive(:new).and_return(@gate)
        @result = subject.enable(five_percent_of_random)
      end

      it "returns true" do
        @result.should be_true
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
        adapter.set_members('features').should include('search')
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
        subject.enable admin_group
        subject.enable pitt
        subject.enable five_percent_of_actors
        subject.enable five_percent_of_random
        @result = subject.disable
      end

      it "returns true" do
        @result.should be_true
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
        enabled = (1..100).select { |i|
          thing = actor_class.new(i)
          subject.enabled?(thing)
        }.size

        enabled.should be(0)
      end

      it "disables percentage of random" do
        subject.enabled?(pitt).should be_false
      end

      it "adds feature to set of features" do
        adapter.set_members('features').should include('search')
      end
    end

    context "with a group" do
      before do
        subject.enable dev_group
        subject.enable admin_group
        @result = subject.disable(admin_group)
      end

      it "returns true" do
        @result.should be_true
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
        adapter.set_members('features').should include('search')
      end
    end

    context "with an actor" do
      before do
        subject.enable pitt
        subject.enable clooney
        @result = subject.disable(pitt)
      end

      it "returns true" do
        @result.should be_true
      end

      it "disables feature for actor" do
        subject.enabled?(pitt).should be_false
      end

      it "does not disable feature for other actors" do
        subject.enabled?(clooney).should be_true
      end

      it "adds feature to set of features" do
        adapter.set_members('features').should include('search')
      end
    end

    context "with a percentage of actors" do
      before do
        @result = subject.disable(five_percent_of_actors)
      end

      it "returns true" do
        @result.should be_true
      end

      it "disables feature" do
        enabled = (1..100).select { |i|
          thing = actor_class.new(i)
          subject.enabled?(thing)
        }.size

        enabled.should be(0)
      end

      it "adds feature to set of features" do
        adapter.set_members('features').should include('search')
      end
    end

    context "with a percentage of time" do
      before do
        @gate = Flipper::Gates::PercentageOfRandom.new(subject)
        Flipper::Gates::PercentageOfRandom.should_receive(:new).and_return(@gate)
        @result = subject.disable(five_percent_of_random)
      end

      it "returns true" do
        @result.should be_true
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
        adapter.set_members('features').should include('search')
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
        subject.enable
      end

      it "returns true" do
        subject.enabled?.should be_true
      end
    end

    context "for actor in enabled group" do
      before do
        subject.enable admin_group
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
        subject.enable pitt
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
        subject.enable
        subject.enabled?(clooney).should be_true
      end
    end

    context "during enabled percentage of time" do
      before do
        @gate = Flipper::Gates::PercentageOfRandom.new(subject)
        @gate.stub(:rand => 0.04)
        Flipper::Gates::PercentageOfRandom.should_receive(:new).and_return(@gate)
        subject.enable five_percent_of_random
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
        subject.enable five_percent_of_random
      end

      it "returns false" do
        subject.enabled?.should be_false
        subject.enabled?(nil).should be_false
        subject.enabled?(pitt).should be_false
        subject.enabled?(admin_thing).should be_false
      end

      it "returns true if boolean enabled" do
        subject.enable
        subject.enabled?.should be_true
        subject.enabled?(nil).should be_true
        subject.enabled?(pitt).should be_true
        subject.enabled?(admin_thing).should be_true
      end
    end

    context "for a non flipper thing" do
      before do
        subject.enable admin_group
      end

      it "returns true if in enabled group" do
        subject.enabled?(admin_thing).should be_true
      end

      it "returns false if not in enabled group" do
        subject.enabled?(dev_thing).should be_false
      end

      it "returns true if boolean enabled" do
        subject.enable
        subject.enabled?(admin_thing).should be_true
        subject.enabled?(dev_thing).should be_true
      end
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
