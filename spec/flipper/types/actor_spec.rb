require 'flipper/types/actor'

RSpec.describe Flipper::Types::Actor do
  subject do
    actor = actor_class.new('2')
    described_class.new(actor)
  end

  let(:actor_class) do
    Class.new do
      attr_reader :flipper_id

      def initialize(flipper_id)
        @flipper_id = flipper_id.to_s
      end

      def admin?
        true
      end

      def flipper_properties
        {
          "flipper_id" => flipper_id,
          "admin" => admin?,
        }
      end
    end
  end

  describe '.wrappable?' do
    it 'returns true if actor' do
      actor = actor_class.new('1')
      actor_type_instance = described_class.new(actor)
      expect(described_class.wrappable?(actor_type_instance)).to eq(true)
    end

    it 'returns true if responds to flipper_id' do
      actor = actor_class.new(10)
      expect(described_class.wrappable?(actor)).to eq(true)
    end

    it 'returns false if nil' do
      expect(described_class.wrappable?(nil)).to be(false)
    end
  end

  describe '.wrap' do
    context 'for actor type instance' do
      it 'returns actor type instance' do
        actor_type_instance = described_class.wrap(subject)
        expect(actor_type_instance).to be_instance_of(described_class)
        expect(actor_type_instance).to be(subject)
      end
    end

    context 'for other object' do
      it 'returns actor type instance' do
        actor = actor_class.new('1')
        actor_type_instance = described_class.wrap(actor)
        expect(actor_type_instance).to be_instance_of(described_class)
      end
    end
  end

  it 'initializes with object that responds to flipper_id' do
    actor = actor_class.new('1')
    actor_type_instance = described_class.new(actor)
    expect(actor_type_instance.value).to eq('1')
  end

  it 'raises error when initialized with nil' do
    expect do
      described_class.new(nil)
    end.to raise_error(ArgumentError)
  end

  it 'raises error when initalized with non-wrappable object' do
    unwrappable_object = Struct.new(:id).new(1)
    expect do
      described_class.new(unwrappable_object)
    end.to raise_error(ArgumentError,
                       "#{unwrappable_object.inspect} must respond to flipper_id, but does not")
  end

  it 'converts id to string' do
    actor = actor_class.new(2)
    actor = described_class.new(actor)
    expect(actor.value).to eq('2')
  end

  it 'proxies everything to actor' do
    actor = actor_class.new(10)
    actor = described_class.new(actor)
    expect(actor.admin?).to eq(true)
  end

  it 'proxies flipper_properties to actor' do
    actor = actor_class.new(10)
    actor = described_class.new(actor)
    expect(actor.flipper_properties).to eq({
      "flipper_id" => "10",
      "admin" => true,
    })
  end

  it 'exposes actor' do
    actor = actor_class.new(10)
    actor_type_instance = described_class.new(actor)
    expect(actor_type_instance.actor).to be(actor)
  end

  describe '#respond_to?' do
    it 'returns true if responds to method' do
      actor = actor_class.new('1')
      actor_type_instance = described_class.new(actor)
      expect(actor_type_instance.respond_to?(:value)).to eq(true)
    end

    it 'returns true if actor responds to method' do
      actor = actor_class.new(10)
      actor_type_instance = described_class.new(actor)
      expect(actor_type_instance.respond_to?(:admin?)).to eq(true)
      expect(actor_type_instance.respond_to?(:flipper_properties)).to eq(true)
    end

    it 'returns false if does not respond to method and actor does not respond to method' do
      actor = actor_class.new(10)
      actor_type_instance = described_class.new(actor)
      expect(actor_type_instance.respond_to?(:frankenstein)).to eq(false)
    end
  end
end
