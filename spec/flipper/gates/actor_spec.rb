RSpec.describe Flipper::Gates::Actor do
  let(:feature_name) { :search }

  subject do
    described_class.new
  end

  def context(enabled_actor_ids, actors = nil)
    Flipper::FeatureCheckContext.new(
      feature_name: feature_name,
      values: Flipper::GateValues.new(actors: enabled_actor_ids),
      actors: Array(actors)
    )
  end

  describe '#open?' do
    it 'returns false when no actors are passed in' do
      expect(subject.open?(context(Set['User;1'], nil))).to be(false)
    end

    it 'returns false when no actors are enabled' do
      actor = Flipper::Types::Actor.new(Flipper::Actor.new('User;1'))
      expect(subject.open?(context(Set.new, actor))).to be(false)
    end

    it 'returns true when any passed in actor is enabled' do
      actors = [
        Flipper::Types::Actor.new(Flipper::Actor.new('User;1')),
        Flipper::Types::Actor.new(Flipper::Actor.new('User;2')),
      ]
      expect(subject.open?(context(Set['User;2'], actors))).to be(true)
    end

    it 'returns false when none of the passed in actors are enabled' do
      actor = Flipper::Types::Actor.new(Flipper::Actor.new('User;1'))
      expect(subject.open?(context(Set['User;2'], actor))).to be(false)
    end
  end
end
