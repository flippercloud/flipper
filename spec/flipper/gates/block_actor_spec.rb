RSpec.describe Flipper::Gates::BlockActor do
  let(:feature_name) { :search }

  subject do
    described_class.new
  end

  def context(set, actors: [Flipper::Types::Actor.new(Flipper::Actor.new('5'))])
    Flipper::FeatureCheckContext.new(
      feature_name: feature_name,
      values: Flipper::GateValues.new(block_actors: set),
      actors: actors
    )
  end

  describe '#blocks?' do
    it 'returns true when actor is in blocked set' do
      expect(subject.blocks?(context(Set['5']))).to be(true)
    end

    it 'returns false when actor is not in blocked set' do
      expect(subject.blocks?(context(Set['10']))).to be(false)
    end

    it 'returns false when blocked set is empty' do
      expect(subject.blocks?(context(Set.new))).to be(false)
    end

    it 'returns false when no actors in context' do
      expect(subject.blocks?(context(Set['5'], actors: []))).to be(false)
    end
  end

  describe '#open?' do
    it 'always returns false' do
      expect(subject.open?(context(Set['5']))).to be(false)
    end
  end

  describe '#wrap' do
    it 'returns actor instance' do
      actor = Flipper::Actor.new('5')
      result = subject.wrap(actor)
      expect(result).to be_instance_of(Flipper::Types::Actor)
      expect(result.value).to eq('5')
    end
  end

  describe '#protects?' do
    it 'returns true for actor' do
      actor = Flipper::Actor.new('5')
      expect(subject.protects?(actor)).to be(true)
    end

    it 'returns false for non-actor' do
      expect(subject.protects?(:admins)).to be(false)
    end
  end
end
