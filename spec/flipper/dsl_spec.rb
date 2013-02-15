require 'helper'
require 'flipper/dsl'
require 'flipper/adapters/memory'

describe Flipper::DSL do
  subject { Flipper::DSL.new(adapter) }

  let(:source)  { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }

  describe "#initialize" do
    it "wraps adapter" do
      dsl = described_class.new(adapter)
      dsl.adapter.should be_instance_of(Flipper::Adapter)
      dsl.adapter.adapter.should eq(adapter)
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

      it "returns group" do
        subject.group(:admins).should eq(@group)
      end

      it "always returns same instance for same name" do
        subject.group(:admins).should equal(subject.group(:admins))
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

  describe "#random" do
    before do
      @result = subject.random(5)
    end

    it "returns percentage of random" do
      @result.should be_instance_of(Flipper::Types::PercentageOfRandom)
    end

    it "sets value" do
      @result.value.should eq(5)
    end

    it "is aliased to percentage_of_random" do
      @result.should eq(subject.percentage_of_random(@result.value))
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
end
