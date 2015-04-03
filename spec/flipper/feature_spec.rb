require 'helper'
require 'flipper/feature'
require 'flipper/adapters/memory'
require 'flipper/instrumenters/memory'

describe Flipper::Feature do
  subject { described_class.new(:search, adapter) }

  let(:source) { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }

  describe "#initialize" do
    it "sets name" do
      feature = described_class.new(:search, adapter)
      feature.name.should eq(:search)
    end

    it "sets adapter" do
      feature = described_class.new(:search, adapter)
      feature.adapter.should eq(adapter)
    end

    it "defaults instrumenter" do
      feature = described_class.new(:search, adapter)
      feature.instrumenter.should be(Flipper::Instrumenters::Noop)
    end

    context "with overriden instrumenter" do
      let(:instrumenter) { double('Instrumentor', :instrument => nil) }

      it "overrides default instrumenter" do
        feature = described_class.new(:search, adapter, {
          :instrumenter => instrumenter,
        })
        feature.instrumenter.should be(instrumenter)
      end
    end
  end

  describe "#to_s" do
    it "returns name as string" do
      feature = described_class.new(:search, adapter)
      feature.to_s.should eq("search")
    end
  end

  describe "#to_param" do
    it "returns name as string" do
      feature = described_class.new(:search, adapter)
      feature.to_param.should eq("search")
    end
  end

  describe "#gate_for" do
    context "with percentage of actors" do
      it "returns percentage of actors gate" do
        percentage = Flipper::Types::PercentageOfActors.new(10)
        gate = subject.gate_for(percentage)
        gate.should be_instance_of(Flipper::Gates::PercentageOfActors)
      end
    end
  end

  describe "#gates" do
    it "returns array of gates" do
      instance = described_class.new(:search, adapter)
      instance.gates.should be_instance_of(Array)
      instance.gates.each do |gate|
        gate.should be_a(Flipper::Gate)
      end
      instance.gates.size.should be(5)
    end
  end

  describe "#gate" do
    context "with symbol name" do
      it "returns gate by name" do
        boolean_gate = subject.gates.detect { |gate| gate.name == :boolean }
        subject.gate(:boolean).should eq(boolean_gate)
      end
    end

    context "with string name" do
      it "returns gate by name" do
        boolean_gate = subject.gates.detect { |gate| gate.name == :boolean }
        subject.gate('boolean').should eq(boolean_gate)
      end
    end

    context "with name that does not exist" do
      it "returns nil" do
        subject.gate(:poo).should be_nil
      end
    end
  end

  describe "#inspect" do
    it "returns easy to read string representation" do
      string = subject.inspect
      string.should include('Flipper::Feature')
      string.should include('name=:search')
      string.should include('state=:off')
      string.should include('description="Disabled"')
      string.should include("adapter=#{subject.adapter.name.inspect}")
    end
  end

  describe "instrumentation" do
    let(:instrumenter) { Flipper::Instrumenters::Memory.new }

    subject {
      described_class.new(:search, adapter, :instrumenter => instrumenter)
    }

    it "is recorded for enable" do
      thing = Flipper::Types::Boolean.new
      gate = subject.gate_for(thing)

      subject.enable(thing)

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('feature_operation.flipper')
      event.payload[:feature_name].should eq(:search)
      event.payload[:operation].should eq(:enable)
      event.payload[:thing].should eq(thing)
      event.payload[:result].should_not be_nil
    end

    it "is recorded for disable" do
      thing = Flipper::Types::Boolean.new
      gate = subject.gate_for(thing)

      subject.disable(thing)

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('feature_operation.flipper')
      event.payload[:feature_name].should eq(:search)
      event.payload[:operation].should eq(:disable)
      event.payload[:thing].should eq(thing)
      event.payload[:result].should_not be_nil
    end

    it "is recorded for enabled?" do
      thing = Flipper::Types::Boolean.new
      gate = subject.gate_for(thing)

      subject.enabled?(thing)

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('feature_operation.flipper')
      event.payload[:feature_name].should eq(:search)
      event.payload[:operation].should eq(:enabled?)
      event.payload[:thing].should eq(thing)
      event.payload[:result].should eq(false)
    end
  end

  describe "#state" do
    context "fully on" do
      before do
        subject.enable
      end

      it "returns :on" do
        subject.state.should be(:on)
      end

      it "returns true for on?" do
        subject.on?.should be(true)
      end

      it "returns false for off?" do
        subject.off?.should be(false)
      end

      it "returns false for conditional?" do
        subject.conditional?.should be(false)
      end
    end

    context "fully off" do
      before do
        subject.disable
      end

      it "returns :off" do
        subject.state.should be(:off)
      end

      it "returns false for on?" do
        subject.on?.should be(false)
      end

      it "returns true for off?" do
        subject.off?.should be(true)
      end

      it "returns false for conditional?" do
        subject.conditional?.should be(false)
      end
    end

    context "partially on" do
      before do
        subject.enable Flipper::Types::PercentageOfRandom.new(5)
      end

      it "returns :conditional" do
        subject.state.should be(:conditional)
      end

      it "returns false for on?" do
        subject.on?.should be(false)
      end

      it "returns false for off?" do
        subject.off?.should be(false)
      end

      it "returns true for conditional?" do
        subject.conditional?.should be(true)
      end
    end
  end

  describe "#description" do
    context "fully on" do
      before do
        subject.enable
      end

      it "returns enabled" do
        subject.description.should eq('Enabled')
      end
    end

    context "fully off" do
      before do
        subject.disable
      end

      it "returns disabled" do
        subject.description.should eq('Disabled')
      end
    end

    context "partially on" do
      before do
        actor = Struct.new(:flipper_id).new(5)
        subject.enable Flipper::Types::PercentageOfRandom.new(5)
        subject.enable actor
      end

      it "returns text" do
        subject.description.should eq('Enabled for actors ("5"), 5% of the time')
      end
    end
  end

  describe "#enabled_groups" do
    context "when no groups enabled" do
      it "returns empty set" do
        subject.enabled_groups.should eq(Set.new)
      end
    end

    context "when one or more groups enabled" do
      before do
        @staff = Flipper.register(:staff) { |thing| true }
        @preview_features = Flipper.register(:preview_features) { |thing| true }
        @not_enabled = Flipper.register(:not_enabled) { |thing| true }
        @disabled = Flipper.register(:disabled) { |thing| true }
        subject.enable @staff
        subject.enable @preview_features
        subject.disable @disabled
      end

      it "returns set of enabled groups" do
        subject.enabled_groups.should eq(Set.new([
          @staff,
          @preview_features,
        ]))
      end

      it "does not include groups that have not been enabled" do
        subject.enabled_groups.should_not include(@not_enabled)
      end

      it "does not include disabled groups" do
        subject.enabled_groups.should_not include(@disabled)
      end

      it "is aliased to groups" do
        subject.enabled_groups.should eq(subject.groups)
      end
    end
  end

  describe "#disabled_groups" do
    context "when no groups enabled" do
      it "returns empty set" do
        subject.disabled_groups.should eq(Set.new)
      end
    end

    context "when one or more groups enabled" do
      before do
        @staff = Flipper.register(:staff) { |thing| true }
        @preview_features = Flipper.register(:preview_features) { |thing| true }
        @not_enabled = Flipper.register(:not_enabled) { |thing| true }
        @disabled = Flipper.register(:disabled) { |thing| true }
        subject.enable @staff
        subject.enable @preview_features
        subject.disable @disabled
      end

      it "returns set of groups that are not enabled" do
        subject.disabled_groups.should eq(Set[
          @not_enabled,
          @disabled,
        ])
      end
    end
  end

  describe "#groups_value" do
    context "when no groups enabled" do
      it "returns empty set" do
        subject.groups_value.should eq(Set.new)
      end
    end

    context "when one or more groups enabled" do
      before do
        @staff = Flipper.register(:staff) { |thing| true }
        @preview_features = Flipper.register(:preview_features) { |thing| true }
        @not_enabled = Flipper.register(:not_enabled) { |thing| true }
        @disabled = Flipper.register(:disabled) { |thing| true }
        subject.enable @staff
        subject.enable @preview_features
        subject.disable @disabled
      end

      it "returns set of enabled groups" do
        subject.groups_value.should eq(Set.new([
          @staff.name.to_s,
          @preview_features.name.to_s,
        ]))
      end

      it "does not include groups that have not been enabled" do
        subject.groups_value.should_not include(@not_enabled.name.to_s)
      end

      it "does not include disabled groups" do
        subject.groups_value.should_not include(@disabled.name.to_s)
      end
    end
  end

  describe "#actors_value" do
    context "when no groups enabled" do
      it "returns empty set" do
        subject.actors_value.should eq(Set.new)
      end
    end

    context "when one or more actors are enabled" do
      before do
        subject.enable Flipper::Types::Actor.new(Struct.new(:flipper_id).new("User:5"))
        subject.enable Flipper::Types::Actor.new(Struct.new(:flipper_id).new("User:22"))
      end

      it "returns set of actor ids" do
        subject.actors_value.should eq(Set.new(["User:5", "User:22"]))
      end
    end
  end

  describe "#boolean_value" do
    context "when not enabled or disabled" do
      it "returns false" do
        subject.boolean_value.should be(false)
      end
    end

    context "when enabled" do
      before do
        subject.enable
      end

      it "returns true" do
        subject.boolean_value.should be(true)
      end
    end

    context "when disabled" do
      before do
        subject.disable
      end

      it "returns false" do
        subject.boolean_value.should be(false)
      end
    end
  end

  describe "#percentage_of_actors_value" do
    context "when not enabled or disabled" do
      it "returns nil" do
        subject.percentage_of_actors_value.should be(0)
      end
    end

    context "when enabled" do
      before do
        subject.enable Flipper::Types::PercentageOfActors.new(5)
      end

      it "returns true" do
        subject.percentage_of_actors_value.should eq(5)
      end
    end

    context "when disabled" do
      before do
        subject.disable
      end

      it "returns nil" do
        subject.percentage_of_actors_value.should be(0)
      end
    end
  end

  describe "#percentage_of_random_value" do
    context "when not enabled or disabled" do
      it "returns nil" do
        subject.percentage_of_random_value.should be(0)
      end
    end

    context "when enabled" do
      before do
        subject.enable Flipper::Types::PercentageOfRandom.new(5)
      end

      it "returns true" do
        subject.percentage_of_random_value.should eq(5)
      end
    end

    context "when disabled" do
      before do
        subject.disable
      end

      it "returns nil" do
        subject.percentage_of_random_value.should be(0)
      end
    end
  end

  describe "#gate_values" do
    context "when no gates are set in adapter" do
      it "returns default gate values" do
        subject.gate_values.should eq(Flipper::GateValues.new({
          :actors => Set.new,
          :groups => Set.new,
          :boolean => nil,
          :percentage_of_actors => nil,
          :percentage_of_random => nil,
        }))
      end
    end

    context "with gate values set in adapter" do
      before do
        subject.enable Flipper::Types::Boolean.new(true)
        subject.enable Flipper::Types::Actor.new(Struct.new(:flipper_id).new(5))
        subject.enable Flipper::Types::Group.new(:admins)
        subject.enable Flipper::Types::PercentageOfRandom.new(50)
        subject.enable Flipper::Types::PercentageOfActors.new(25)
      end

      it "returns gate values" do
        subject.gate_values.should eq(Flipper::GateValues.new({
          :actors => Set.new(["5"]),
          :groups => Set.new(["admins"]),
          :boolean => "true",
          :percentage_of_random => "50",
          :percentage_of_actors => "25",
        }))
      end
    end
  end

  describe "#enable_actor/disable_actor" do
    context "with object that responds to flipper_id" do
      it "updates the gate values to include the actor" do
        actor = Struct.new(:flipper_id).new(5)
        subject.gate_values.actors.should be_empty
        subject.enable_actor(actor)
        subject.gate_values.actors.should eq(Set["5"])
        subject.disable_actor(actor)
        subject.gate_values.actors.should be_empty
      end
    end

    context "with actor instance" do
      it "updates the gate values to include the actor" do
        actor = Struct.new(:flipper_id).new(5)
        instance = Flipper::Types::Actor.wrap(actor)
        subject.gate_values.actors.should be_empty
        subject.enable_actor(instance)
        subject.gate_values.actors.should eq(Set["5"])
        subject.disable_actor(instance)
        subject.gate_values.actors.should be_empty
      end
    end
  end

  describe "#enable_group/disable_group" do
    context "with symbol group name" do
      it "updates the gate values to include the group" do
        actor = Struct.new(:flipper_id).new(5)
        group = Flipper.register(:five_only) { |actor| actor.flipper_id == 5 }
        subject.gate_values.groups.should be_empty
        subject.enable_group(:five_only)
        subject.gate_values.groups.should eq(Set["five_only"])
        subject.disable_group(:five_only)
        subject.gate_values.groups.should be_empty
      end
    end

    context "with string group name" do
      it "updates the gate values to include the group" do
        actor = Struct.new(:flipper_id).new(5)
        group = Flipper.register(:five_only) { |actor| actor.flipper_id == 5 }
        subject.gate_values.groups.should be_empty
        subject.enable_group("five_only")
        subject.gate_values.groups.should eq(Set["five_only"])
        subject.disable_group("five_only")
        subject.gate_values.groups.should be_empty
      end
    end

    context "with group instance" do
      it "updates the gate values for the group" do
        actor = Struct.new(:flipper_id).new(5)
        group = Flipper.register(:five_only) { |actor| actor.flipper_id == 5 }
        subject.gate_values.groups.should be_empty
        subject.enable_group(group)
        subject.gate_values.groups.should eq(Set["five_only"])
        subject.disable_group(group)
        subject.gate_values.groups.should be_empty
      end
    end
  end

  describe "#enable_percentage_of_random/disable_percentage_of_random" do
    context "with integer" do
      it "updates the gate values" do
        subject.gate_values.percentage_of_random.should be(0)
        subject.enable_percentage_of_random(56)
        subject.gate_values.percentage_of_random.should be(56)
        subject.disable_percentage_of_random
        subject.gate_values.percentage_of_random.should be(0)
      end
    end

    context "with string" do
      it "updates the gate values" do
        subject.gate_values.percentage_of_random.should be(0)
        subject.enable_percentage_of_random("56")
        subject.gate_values.percentage_of_random.should be(56)
        subject.disable_percentage_of_random
        subject.gate_values.percentage_of_random.should be(0)
      end
    end

    context "with percentage of random instance" do
      it "updates the gate values" do
        percentage = Flipper::Types::PercentageOfRandom.new(56)
        subject.gate_values.percentage_of_random.should be(0)
        subject.enable_percentage_of_random(percentage)
        subject.gate_values.percentage_of_random.should be(56)
        subject.disable_percentage_of_random
        subject.gate_values.percentage_of_random.should be(0)
      end
    end
  end

  describe "#enable_percentage_of_actors/disable_percentage_of_actors" do
    context "with integer" do
      it "updates the gate values" do
        subject.gate_values.percentage_of_actors.should be(0)
        subject.enable_percentage_of_actors(56)
        subject.gate_values.percentage_of_actors.should be(56)
        subject.disable_percentage_of_actors
        subject.gate_values.percentage_of_actors.should be(0)
      end
    end

    context "with string" do
      it "updates the gate values" do
        subject.gate_values.percentage_of_actors.should be(0)
        subject.enable_percentage_of_actors("56")
        subject.gate_values.percentage_of_actors.should be(56)
        subject.disable_percentage_of_actors
        subject.gate_values.percentage_of_actors.should be(0)
      end
    end

    context "with percentage of actors instance" do
      it "updates the gate values" do
        percentage = Flipper::Types::PercentageOfActors.new(56)
        subject.gate_values.percentage_of_actors.should be(0)
        subject.enable_percentage_of_actors(percentage)
        subject.gate_values.percentage_of_actors.should be(56)
        subject.disable_percentage_of_actors
        subject.gate_values.percentage_of_actors.should be(0)
      end
    end
  end
end
