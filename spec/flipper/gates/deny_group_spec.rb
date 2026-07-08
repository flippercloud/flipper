RSpec.describe Flipper::Gates::DenyGroup do
  let(:feature_name) { :search }

  subject do
    described_class.new
  end

  def context(set)
    Flipper::FeatureCheckContext.new(
      feature_name: feature_name,
      values: Flipper::GateValues.new(deny_groups: set),
      actors: [Flipper::Types::Actor.new(Flipper::Actor.new('5'))]
    )
  end

  describe '#blocks?' do
    context 'with a matching registered group' do
      before do
        Flipper.register(:staff) { |actor| true }
      end

      it 'returns true when actor matches denied group' do
        expect(subject.blocks?(context(Set[:staff]))).to be(true)
      end
    end

    context 'with a non-matching registered group' do
      before do
        Flipper.register(:staff) { |actor| false }
      end

      it 'returns false when actor does not match denied group' do
        expect(subject.blocks?(context(Set[:staff]))).to be(false)
      end
    end

    it 'returns false when denied set is empty' do
      expect(subject.blocks?(context(Set.new))).to be(false)
    end

    context 'with a group in adapter, but not registered' do
      before do
        Flipper.register(:staff) { |actor| true }
      end

      it 'ignores unregistered group' do
        expect(subject.blocks?(context(Set[:newbs]))).to be(false)
      end
    end
  end

  describe '#open?' do
    before do
      Flipper.register(:staff) { |actor| true }
    end

    it 'always returns false' do
      expect(subject.open?(context(Set[:staff]))).to be(false)
    end
  end

  describe '#wrap' do
    it 'returns group instance for symbol' do
      group = Flipper.register(:admins) {}
      expect(subject.wrap(:admins)).to eq(group)
    end

    it 'returns group instance for group instance' do
      group = Flipper.register(:admins) {}
      expect(subject.wrap(group)).to eq(group)
    end
  end

  describe '#protects?' do
    it 'returns true for group' do
      group = Flipper.register(:admins) {}
      expect(subject.protects?(group)).to be(true)
    end

    it 'returns true for symbol' do
      expect(subject.protects?(:admins)).to be(true)
    end
  end
end
