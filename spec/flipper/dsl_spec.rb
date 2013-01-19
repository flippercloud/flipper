require 'helper'
require 'flipper/dsl'
require 'flipper/adapters/memory'

describe Flipper::DSL do
  subject { Flipper::DSL.new(adapter) }

  let(:source)  { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }

  let(:admins_feature) { Flipper::Feature.new(:admins, adapter) }

  describe "#initialize" do
    it "wraps adapter" do
      dsl = described_class.new(adapter)
      dsl.adapter.should be_instance_of(Flipper::Adapter)
      dsl.adapter.adapter.should eq(adapter)
    end

    it "defaults instrumentor to noop" do
      dsl = described_class.new(adapter)
      dsl.instrumentor.should be(Flipper::Instrumentors::Noop)
    end

    context "with overriden instrumentor" do
      let(:instrumentor) { double('Instrumentor', :instrument => nil) }

      it "overrides default instrumentor" do
        dsl = described_class.new(adapter, :instrumentor => instrumentor)
        dsl.instrumentor.should be(instrumentor)
      end

      it "passes overridden instrumentor to adapter wrapping" do
        dsl = described_class.new(adapter, :instrumentor => instrumentor)
        dsl.adapter.instrumentor.should be(instrumentor)
      end
    end
  end

  describe "#enabled?" do
    before do
      subject.stub(:feature => admins_feature)
    end

    it "passes arguments to feature enabled check and returns result" do
      admins_feature.should_receive(:enabled?).with(:foo).and_return(true)
      subject.should_receive(:feature).with(:stats).and_return(admins_feature)
      subject.enabled?(:stats, :foo).should be_true
    end
  end

  describe "#disabled?" do
    it "passes arguments to feature disabled check and returns result" do
      admins_feature.should_receive(:disabled?).with(:foo).and_return(false)
      subject.should_receive(:feature).with(:stats).and_return(admins_feature)
      subject.disabled?(:stats, :foo).should be_false
    end
  end

  describe "#enable" do
    before do
      subject.stub(:feature => admins_feature)
    end

    it "calls enable for feature with arguments" do
      admins_feature.should_receive(:enable).with(:foo)
      subject.should_receive(:feature).with(:stats).and_return(admins_feature)
      subject.enable :stats, :foo
    end
  end

  describe "#disable" do
    before do
      subject.stub(:feature => admins_feature)
    end

    it "calls disable for feature with arguments" do
      admins_feature.should_receive(:disable).with(:foo)
      subject.should_receive(:feature).with(:stats).and_return(admins_feature)
      subject.disable :stats, :foo
    end
  end

  describe "#feature" do
    it_should_behave_like "a DSL feature" do
      let(:instrumentor) { double('Instrumentor', :instrument => nil) }
      let(:feature) { dsl.feature(:stats) }
      let(:dsl) { Flipper::DSL.new(adapter, :instrumentor => instrumentor) }
    end
  end

  describe "#[]" do
    it_should_behave_like "a DSL feature" do
      let(:instrumentor) { double('Instrumentor', :instrument => nil) }
      let(:feature) { dsl[:stats] }
      let(:dsl) { Flipper::DSL.new(adapter, :instrumentor => instrumentor) }
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
