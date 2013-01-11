require 'helper'
require 'flipper/dsl'
require 'flipper/adapters/memory'

describe Flipper::DSL do
  subject { Flipper::DSL.new(adapter) }

  let(:source)  { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }

  let(:admins_feature) { feature(:admins) }

  def feature(name)
    Flipper::Feature.new(name, adapter)
  end

  describe "#initialize" do
    it "wraps adapter" do
      dsl = described_class.new(adapter)
      dsl.adapter.should be_instance_of(Flipper::Adapter)
      dsl.adapter.adapter.should eq(adapter)
    end

    it "defaults instrumentor to noop" do
      dsl = described_class.new(adapter)
      dsl.instrumentor.should be(Flipper::NoopInstrumentor)
    end

    it "allows setting instrumentor" do
      instrumentor = double('Instrumentor', :instrument => nil)
      dsl = described_class.new(adapter, :instrumentor => instrumentor)
      dsl.instrumentor.should be(instrumentor)
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
    it "passes all args to enabled? and returns the opposite" do
      subject.should_receive(:enabled?).with(:stats, :foo).and_return(true)
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
      it "returns nil" do
        subject.group(:admins).should be_nil
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
      it "raises error" do
        expect {
          subject.actor(nil)
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
