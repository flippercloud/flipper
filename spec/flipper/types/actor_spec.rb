require 'helper'
require 'flipper/types/actor'

describe Flipper::Types::Actor do
  subject {
    described_class.new(2)
  }

  let(:thing_class) {
    Class.new {
      attr_reader :identifier

      def initialize(identifier)
        @identifier = identifier
      end

      def admin?
        true
      end
    }
  }

  describe ".wrappable?" do
    it "returns true if actor" do
      thing = described_class.new(1)
      described_class.wrappable?(thing).should be_true
    end

    it "returns true if responds to identifier" do
      thing = Struct.new(:identifier).new(10)
      described_class.wrappable?(thing).should be_true
    end

    it "returns true if responds to to_i" do
      described_class.wrappable?(1).should be_true
    end

    it "returns false if not actor and does not respond to identifier or to_i" do
      described_class.wrappable?(Object.new).should be_false
    end
  end

  describe ".wrap" do
    context "for actor" do
      it "returns actor" do
        actor = described_class.wrap(subject)
        actor.should be_instance_of(described_class)
        actor.should be(subject)
      end
    end

    context "for other thing" do
      it "returns actor" do
        actor = described_class.wrap(1)
        actor.should be_instance_of(described_class)
      end
    end
  end

  it "initializes with identifier" do
    actor = described_class.new(2)
    actor.should be_instance_of(described_class)
  end

  it "initializes with object that responds to identifier" do
    thing = Struct.new(:identifier).new(1)
    actor = described_class.new(thing)
    actor.identifier.should be(1)
  end

  it "raises error when initialized with nil" do
    expect {
      described_class.new(nil)
    }.to raise_error(ArgumentError)
  end

  it "converts identifier to integer" do
    actor = described_class.new('2')
    actor.identifier.should eq(2)
  end

  it "has identifier" do
    actor = described_class.new(2)
    actor.identifier.should eq(2)
  end

  it "proxies everything to thing" do
    thing = thing_class.new(10)
    actor = described_class.new(thing)
    actor.admin?.should be_true
  end

  describe "#respond_to?" do
    it "returns true if responds to method" do
      actor = described_class.new(10)
      actor.respond_to?(:value).should be_true
    end

    it "returns true if thing responds to method" do
      thing = thing_class.new(10)
      actor = described_class.new(thing)
      actor.respond_to?(:admin?).should be_true
    end

    it "returns false if does not respond to method and thing does not respond to method" do
      actor = described_class.new(10)
      actor.respond_to?(:frankenstein).should be_false
    end
  end
end
