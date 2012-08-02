require 'helper'
require 'flipper/dsl'

describe Flipper::DSL do
  subject { Flipper::DSL.new(adapter) }

  let(:source)  { {} }
  let(:adapter) { Flipper::Adapters::Memory.new(source) }

  let(:admins_feature) { feature(:admins) }

  before do
    Flipper.groups = Flipper::Registry.new
  end

  def feature(name)
    Flipper::Feature.new(name, adapter)
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
    before do
      @result = subject.feature(:stats)
    end

    it "returns instance of feature with correct name and adapter" do
      @result.should be_instance_of(Flipper::Feature)
      @result.name.should eq(:stats)
      @result.adapter.should eq(adapter)
    end

    it "memoizes the feature" do
      subject.feature(:stats).should equal(@result)
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
    end

    context "for unregistered group" do
      it "returns nil" do
        subject.group(:admins).should be_nil
      end
    end
  end

  describe "#actor" do
    context "for something that responds to id" do
      it "returns actor instance with identifier set to id" do
        user = Struct.new(:id).new(23)
        actor = subject.actor(user)
        actor.should be_instance_of(Flipper::Types::Actor)
        actor.identifier.should eq(23)
      end
    end

    context "for something that responds to identifier" do
      it "returns actor instance with identifier set to id" do
        user = Struct.new(:identifier).new(45)
        actor = subject.actor(user)
        actor.should be_instance_of(Flipper::Types::Actor)
        actor.identifier.should eq(45)
      end
    end

    context "for something that responds to identifier and id" do
      it "returns actor instance with identifier set to identifier" do
        user = Struct.new(:id, :identifier).new(1, 50)
        actor = subject.actor(user)
        actor.should be_instance_of(Flipper::Types::Actor)
        actor.identifier.should eq(50)
      end
    end

    context "for a number" do
      it "returns actor instance with identifer set to number" do
        actor = subject.actor(33)
        actor.should be_instance_of(Flipper::Types::Actor)
        actor.identifier.should eq(33)
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
end
