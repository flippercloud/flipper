require 'helper'
require 'flipper/dsl'
require 'flipper/adapters/memory'

describe Flipper::DSL do
  subject { Flipper::DSL.new(adapter) }

  let(:adapter) { Flipper::Adapters::Memory.new }

  describe "#initialize" do
    it "sets adapter" do
      dsl = described_class.new(adapter)
      dsl.adapter.should_not be_nil
    end

    it "defaults instrumenter to noop" do
      dsl = described_class.new(adapter)
      dsl.instrumenter.should be(Flipper::Instrumenters::Noop)
    end

    context "with overriden instrumenter" do
      let(:instrumenter) { double('Instrumentor', :instrument => nil) }

      it "overrides default instrumenter" do
        dsl = described_class.new(adapter, :instrumenter => instrumenter)
        dsl.instrumenter.should be(instrumenter)
      end

      it "passes overridden instrumenter to adapter wrapping" do
        dsl = described_class.new(adapter, :instrumenter => instrumenter)
        dsl.adapter.instrumenter.should be(instrumenter)
      end
    end
  end

  describe "#feature" do
    it_should_behave_like "a DSL feature" do
      let(:method_name) { :feature }
      let(:instrumenter) { double('Instrumentor', :instrument => nil) }
      let(:feature) { dsl.send(method_name, :stats) }
      let(:dsl) { Flipper::DSL.new(adapter, :instrumenter => instrumenter) }
    end
  end

  describe "#[]" do
    it_should_behave_like "a DSL feature" do
      let(:method_name) { :[] }
      let(:instrumenter) { double('Instrumentor', :instrument => nil) }
      let(:feature) { dsl.send(method_name, :stats) }
      let(:dsl) { Flipper::DSL.new(adapter, :instrumenter => instrumenter) }
    end
  end

  describe "#boolean" do
    it_should_behave_like "a DSL boolean method" do
      let(:method_name) { :boolean }
    end
  end

  describe "#bool" do
    it_should_behave_like "a DSL boolean method" do
      let(:method_name) { :bool }
    end
  end

  describe "#group" do
    context "for registered group" do
      before do
        @group = Flipper.register(:admins) { }
      end

      it "returns group instance" do
        subject.group(:admins).should be_instance_of(Flipper::Types::Group)
      end
    end

    context "for unregistered group" do
      it "raises error" do
        expect {
          subject.group(:admins)
        }.to raise_error(Flipper::GroupNotRegistered)
      end
    end
  end

  describe "#actor" do
    context "for a thing" do
      it "returns actor instance" do
        thing = Struct.new(:flipper_id).new(33)
        actor = subject.actor(thing)
        actor.should be_instance_of(Flipper::Types::Actor)
        actor.value.should eq('33')
      end
    end

    context "for nil" do
      it "raises argument error" do
        expect {
          subject.actor(nil)
        }.to raise_error(ArgumentError)
      end
    end

    context "for something that is not actor wrappable" do
      it "raises argument error" do
        expect {
          subject.actor(Object.new)
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#time" do
    before do
      @result = subject.time(5)
    end

    it "returns percentage of time" do
      @result.should be_instance_of(Flipper::Types::PercentageOfTime)
    end

    it "sets value" do
      @result.value.should eq(5)
    end

    it "is aliased to percentage_of_time" do
      @result.should eq(subject.percentage_of_time(@result.value))
    end
  end

  describe "#actors" do
    before do
      @result = subject.actors(17)
    end

    it "returns percentage of actors" do
      @result.should be_instance_of(Flipper::Types::PercentageOfActors)
    end

    it "sets value" do
      @result.value.should eq(17)
    end

    it "is aliased to percentage_of_actors" do
      @result.should eq(subject.percentage_of_actors(@result.value))
    end
  end

  describe "#features" do
    context "with no features enabled/disabled" do
      it "defaults to empty set" do
        subject.features.should eq(Set.new)
      end
    end

    context "with features enabled and disabled" do
      before do
        subject[:stats].enable
        subject[:cache].enable
        subject[:search].disable
      end

      it "returns set of feature instances" do
        subject.features.should be_instance_of(Set)
        subject.features.each do |feature|
          feature.should be_instance_of(Flipper::Feature)
        end
        subject.features.map(&:name).map(&:to_s).sort.should eq(['cache', 'search', 'stats'])
      end
    end
  end

  describe "#enable/disable" do
    it "enables and disables the feature" do
      subject[:stats].boolean_value.should eq(false)
      subject.enable(:stats)
      subject[:stats].boolean_value.should eq(true)

      subject.disable(:stats)
      subject[:stats].boolean_value.should eq(false)
    end
  end

  describe "#enable_actor/disable_actor" do
    it "enables and disables the feature for actor" do
      actor = Struct.new(:flipper_id).new(5)

      subject[:stats].actors_value.should be_empty
      subject.enable_actor(:stats, actor)
      subject[:stats].actors_value.should eq(Set["5"])

      subject.disable_actor(:stats, actor)
      subject[:stats].actors_value.should be_empty
    end
  end

  describe "#enable_group/disable_group" do
    it "enables and disables the feature for group" do
      actor = Struct.new(:flipper_id).new(5)
      group = Flipper.register(:fives) { |actor| actor.flipper_id == 5 }

      subject[:stats].groups_value.should be_empty
      subject.enable_group(:stats, :fives)
      subject[:stats].groups_value.should eq(Set["fives"])

      subject.disable_group(:stats, :fives)
      subject[:stats].groups_value.should be_empty
    end
  end

  describe "#enable_percentage_of_time/disable_percentage_of_time" do
    it "enables and disables the feature for percentage of time" do
      subject[:stats].percentage_of_time_value.should be(0)
      subject.enable_percentage_of_time(:stats, 6)
      subject[:stats].percentage_of_time_value.should be(6)

      subject.disable_percentage_of_time(:stats)
      subject[:stats].percentage_of_time_value.should be(0)
    end
  end

  describe "#enable_percentage_of_actors/disable_percentage_of_actors" do
    it "enables and disables the feature for percentage of time" do
      subject[:stats].percentage_of_actors_value.should be(0)
      subject.enable_percentage_of_actors(:stats, 6)
      subject[:stats].percentage_of_actors_value.should be(6)

      subject.disable_percentage_of_actors(:stats)
      subject[:stats].percentage_of_actors_value.should be(0)
    end
  end
end
