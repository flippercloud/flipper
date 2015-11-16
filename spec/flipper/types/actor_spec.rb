require 'helper'
require 'flipper/types/actor'

RSpec.describe Flipper::Types::Actor do
  subject {
    thing = thing_class.new('2')
    described_class.new(thing)
  }

  let(:thing_class) {
    Class.new {
      attr_reader :flipper_id

      def initialize(flipper_id)
        @flipper_id = flipper_id
      end

      def admin?
        true
      end
    }
  }

  describe ".wrappable?" do
    it "returns true if actor" do
      thing = thing_class.new('1')
      actor = described_class.new(thing)
      expect(described_class.wrappable?(actor)).to eq(true)
    end

    it "returns true if responds to flipper_id" do
      thing = thing_class.new(10)
      expect(described_class.wrappable?(thing)).to eq(true)
    end

    it "returns false if nil" do
      expect(described_class.wrappable?(nil)).to be(false)
    end
  end

  describe ".wrap" do
    context "for actor" do
      it "returns actor" do
        actor = described_class.wrap(subject)
        expect(actor).to be_instance_of(described_class)
        expect(actor).to be(subject)
      end
    end

    context "for other thing" do
      it "returns actor" do
        thing = thing_class.new('1')
        actor = described_class.wrap(thing)
        expect(actor).to be_instance_of(described_class)
      end
    end
  end

  it "initializes with thing that responds to id" do
    thing = thing_class.new('1')
    actor = described_class.new(thing)
    expect(actor.value).to eq('1')
  end

  it "raises error when initialized with nil" do
    expect {
      described_class.new(nil)
    }.to raise_error(ArgumentError)
  end

  it "raises error when initalized with non-wrappable object" do
    unwrappable_thing = Struct.new(:id).new(1)
    expect {
      described_class.new(unwrappable_thing)
    }.to raise_error(ArgumentError, "#{unwrappable_thing.inspect} must respond to flipper_id, but does not")
  end

  it "converts id to string" do
    thing = thing_class.new(2)
    actor = described_class.new(thing)
    expect(actor.value).to eq('2')
  end

  it "proxies everything to thing" do
    thing = thing_class.new(10)
    actor = described_class.new(thing)
    expect(actor.admin?).to eq(true)
  end

  it "exposes thing" do
    thing = thing_class.new(10)
    actor = described_class.new(thing)
    expect(actor.thing).to be(thing)
  end

  describe "#respond_to?" do
    it "returns true if responds to method" do
      thing = thing_class.new('1')
      actor = described_class.new(thing)
      expect(actor.respond_to?(:value)).to eq(true)
    end

    it "returns true if thing responds to method" do
      thing = thing_class.new(10)
      actor = described_class.new(thing)
      expect(actor.respond_to?(:admin?)).to eq(true)
    end

    it "returns false if does not respond to method and thing does not respond to method" do
      thing = thing_class.new(10)
      actor = described_class.new(thing)
      expect(actor.respond_to?(:frankenstein)).to eq(false)
    end
  end
end
