require 'helper'
require 'flipper/feature'
require 'flipper/adapters/memory'

describe Flipper do
  let(:source)      { {} }
  let(:adapter)     { Flipper::Adapters::Memory.new(source) }

  let(:flipper)     { Flipper.new(adapter) }
  let(:feature)     { flipper[:search] }

  let(:actor_class) { Struct.new(:flipper_id) }

  let(:admin_group) { flipper.group(:admins) }
  let(:dev_group)   { flipper.group(:devs) }

  let(:admin_thing) { double 'Non Flipper Thing', :flipper_id => 1,  :admin? => true, :dev? => false }
  let(:dev_thing)   { double 'Non Flipper Thing', :flipper_id => 10, :admin? => false, :dev? => true }

  let(:pitt)        { actor_class.new(1) }
  let(:clooney)     { actor_class.new(10) }

  let(:five_percent_of_actors) { flipper.actors(5) }
  let(:five_percent_of_time) { flipper.time(5) }

  before do
    Flipper.register(:admins) { |thing| thing.admin? }
    Flipper.register(:devs)   { |thing| thing.dev? }
  end

  describe "#enable" do
    context "with no arguments" do
      before do
        @result = feature.enable
      end

      it "returns true" do
        @result.should eq(true)
      end

      it "enables feature for all" do
        feature.enabled?.should eq(true)
      end

      it "adds feature to set of features" do
        flipper.features.map(&:name).should include(:search)
      end
    end

    context "with a group" do
      before do
        @result = feature.enable(admin_group)
      end

      it "returns true" do
        @result.should eq(true)
      end

      it "enables feature for non flipper thing in group" do
        feature.enabled?(admin_thing).should eq(true)
      end

      it "does not enable feature for non flipper thing in other group" do
        feature.enabled?(dev_thing).should eq(false)
      end

      it "enables feature for flipper actor in group" do
        feature.enabled?(flipper.actor(admin_thing)).should eq(true)
      end

      it "does not enable for flipper actor not in group" do
        feature.enabled?(flipper.actor(dev_thing)).should eq(false)
      end

      it "does not enable feature for all" do
        feature.enabled?.should eq(false)
      end

      it "adds feature to set of features" do
        flipper.features.map(&:name).should include(:search)
      end
    end

    context "with an actor" do
      before do
        @result = feature.enable(pitt)
      end

      it "returns true" do
        @result.should eq(true)
      end

      it "enables feature for actor" do
        feature.enabled?(pitt).should eq(true)
      end

      it "does not enable feature for other actors" do
        feature.enabled?(clooney).should eq(false)
      end

      it "adds feature to set of features" do
        flipper.features.map(&:name).should include(:search)
      end
    end

    context "with a percentage of actors" do
      before do
        @result = feature.enable(five_percent_of_actors)
      end

      it "returns true" do
        @result.should eq(true)
      end

      it "enables feature for actor within percentage" do
        enabled = (1..100).select { |i|
          thing = actor_class.new(i)
          feature.enabled?(thing)
        }.size

        enabled.should be_within(2).of(5)
      end

      it "adds feature to set of features" do
        flipper.features.map(&:name).should include(:search)
      end
    end

    context "with a percentage of time" do
      before do
        @gate = feature.gate(:percentage_of_time)
        @result = feature.enable(five_percent_of_time)
      end

      it "returns true" do
        @result.should eq(true)
      end

      it "enables feature for time within percentage" do
        @gate.stub(:rand => 0.04)
        feature.enabled?.should eq(true)
      end

      it "does not enable feature for time not within percentage" do
        @gate.stub(:rand => 0.10)
        feature.enabled?.should eq(false)
      end

      it "adds feature to set of features" do
        flipper.features.map(&:name).should include(:search)
      end
    end

    context "with argument that has no gate" do
      it "raises error" do
        thing = Object.new
        expect {
          feature.enable(thing)
        }.to raise_error(Flipper::GateNotFound, "Could not find gate for #{thing.inspect}")
      end
    end
  end

  describe "#disable" do
    context "with no arguments" do
      before do
        # ensures that time gate is stubbed with result that would be true for pitt
        @gate = feature.gate(:percentage_of_time)
        @gate.stub(:rand => 0.04)

        feature.enable admin_group
        feature.enable pitt
        feature.enable five_percent_of_actors
        feature.enable five_percent_of_time
        @result = feature.disable
      end

      it "returns true" do
        @result.should be(true)
      end

      it "disables feature" do
        feature.enabled?.should eq(false)
      end

      it "disables for individual actor" do
        feature.enabled?(pitt).should eq(false)
      end

      it "disables actor in group" do
        feature.enabled?(admin_thing).should eq(false)
      end

      it "disables actor in percentage of actors" do
        enabled = (1..100).select { |i|
          thing = actor_class.new(i)
          feature.enabled?(thing)
        }.size

        enabled.should be(0)
      end

      it "disables percentage of time" do
        feature.enabled?(pitt).should eq(false)
      end

      it "adds feature to set of features" do
        flipper.features.map(&:name).should include(:search)
      end
    end

    context "with a group" do
      before do
        feature.enable dev_group
        feature.enable admin_group
        @result = feature.disable(admin_group)
      end

      it "returns true" do
        @result.should eq(true)
      end

      it "disables the feature for non flipper thing in the group" do
        feature.enabled?(admin_thing).should eq(false)
      end

      it "does not disable feature for non flipper thing in other groups" do
        feature.enabled?(dev_thing).should eq(true)
      end

      it "disables feature for flipper actor in group" do
        feature.enabled?(flipper.actor(admin_thing)).should eq(false)
      end

      it "does not disable feature for flipper actor in other groups" do
        feature.enabled?(flipper.actor(dev_thing)).should eq(true)
      end

      it "adds feature to set of features" do
        flipper.features.map(&:name).should include(:search)
      end
    end

    context "with an actor" do
      before do
        feature.enable pitt
        feature.enable clooney
        @result = feature.disable(pitt)
      end

      it "returns true" do
        @result.should eq(true)
      end

      it "disables feature for actor" do
        feature.enabled?(pitt).should eq(false)
      end

      it "does not disable feature for other actors" do
        feature.enabled?(clooney).should eq(true)
      end

      it "adds feature to set of features" do
        flipper.features.map(&:name).should include(:search)
      end
    end

    context "with a percentage of actors" do
      before do
        @result = feature.disable(flipper.actors(0))
      end

      it "returns true" do
        @result.should eq(true)
      end

      it "disables feature" do
        enabled = (1..100).select { |i|
          thing = actor_class.new(i)
          feature.enabled?(thing)
        }.size

        enabled.should be(0)
      end

      it "adds feature to set of features" do
        flipper.features.map(&:name).should include(:search)
      end
    end

    context "with a percentage of time" do
      before do
        @gate = feature.gate(:percentage_of_time)
        @result = feature.disable(flipper.time(0))
      end

      it "returns true" do
        @result.should eq(true)
      end

      it "disables feature for time within percentage" do
        @gate.stub(:rand => 0.04)
        feature.enabled?.should eq(false)
      end

      it "disables feature for time not within percentage" do
        @gate.stub(:rand => 0.10)
        feature.enabled?.should eq(false)
      end

      it "adds feature to set of features" do
        flipper.features.map(&:name).should include(:search)
      end
    end

    context "with argument that has no gate" do
      it "raises error" do
        thing = Object.new
        expect {
          feature.disable(thing)
        }.to raise_error(Flipper::GateNotFound, "Could not find gate for #{thing.inspect}")
      end
    end
  end

  describe "#enabled?" do
    context "with no arguments" do
      it "defaults to false" do
        feature.enabled?.should eq(false)
      end
    end

    context "with no arguments, but boolean enabled" do
      before do
        feature.enable
      end

      it "returns true" do
        feature.enabled?.should eq(true)
      end
    end

    context "for actor in enabled group" do
      before do
        feature.enable admin_group
      end

      it "returns true" do
        feature.enabled?(flipper.actor(admin_thing)).should eq(true)
        feature.enabled?(admin_thing).should eq(true)
      end
    end

    context "for actor in disabled group" do
      it "returns false" do
        feature.enabled?(flipper.actor(dev_thing)).should eq(false)
        feature.enabled?(dev_thing).should eq(false)
      end
    end

    context "for enabled actor" do
      before do
        feature.enable pitt
      end

      it "returns true" do
        feature.enabled?(pitt).should eq(true)
      end
    end

    context "for not enabled actor" do
      it "returns false" do
        feature.enabled?(clooney).should eq(false)
      end

      it "returns true if boolean enabled" do
        feature.enable
        feature.enabled?(clooney).should eq(true)
      end
    end

    context "during enabled percentage of time" do
      before do
        # ensure percentage of time returns enabled percentage
        @gate = feature.gate(:percentage_of_time)
        @gate.stub(:rand => 0.04)

        feature.enable five_percent_of_time
      end

      it "returns true" do
        feature.enabled?.should eq(true)
        feature.enabled?(nil).should eq(true)
        feature.enabled?(pitt).should eq(true)
        feature.enabled?(admin_thing).should eq(true)
      end
    end

    context "during not enabled percentage of time" do
      before do
        # ensure percentage of time returns not enabled percentage
        @gate = feature.gate(:percentage_of_time)
        @gate.stub(:rand => 0.10)

        feature.enable five_percent_of_time
      end

      it "returns false" do
        feature.enabled?.should eq(false)
        feature.enabled?(nil).should eq(false)
        feature.enabled?(pitt).should eq(false)
        feature.enabled?(admin_thing).should eq(false)
      end

      it "returns true if boolean enabled" do
        feature.enable
        feature.enabled?.should eq(true)
        feature.enabled?(nil).should eq(true)
        feature.enabled?(pitt).should eq(true)
        feature.enabled?(admin_thing).should eq(true)
      end
    end

    context "for a non flipper thing" do
      before do
        feature.enable admin_group
      end

      it "returns true if in enabled group" do
        feature.enabled?(admin_thing).should eq(true)
      end

      it "returns false if not in enabled group" do
        feature.enabled?(dev_thing).should eq(false)
      end

      it "returns true if boolean enabled" do
        feature.enable
        feature.enabled?(admin_thing).should eq(true)
        feature.enabled?(dev_thing).should eq(true)
      end
    end
  end

  context "enabling multiple groups, disabling everything, then enabling one group" do
    before do
      feature.enable(admin_group)
      feature.enable(dev_group)
      feature.disable
      feature.enable(admin_group)
    end

    it "enables feature for object in enabled group" do
      feature.enabled?(admin_thing).should eq(true)
    end

    it "does not enable feature for object in not enabled group" do
      feature.enabled?(dev_thing).should eq(false)
    end
  end
end
