require 'helper'

RSpec.describe Flipper::Gates::PercentageOfTime do
  let(:feature_name) { :search }

  subject do
    described_class.new
  end

  def context(integer, feature = feature_name, thing = nil)
    Flipper::FeatureCheckContext.new(
      feature_name: feature,
      values: Flipper::GateValues.new(percentage_of_actors: integer),
      thing: thing || Flipper::Types::Actor.new(Flipper::Actor.new(1))
    )
  end

  describe '#open?' do
    context 'for fractional percentage' do
      let(:decimal) { 0.001}
      let(:percentage) { decimal * 100 }
      let(:number_of_actors) { 10_000 }

      let(:actors) do
        (1..number_of_actors).map { |n| Flipper::Actor.new(n) }
      end

      subject { described_class.new }

      it 'enables feature for accurate percentage of time' do
        margin_of_error = 0.02 * number_of_actors
        expected_open_count = 100_000 * decimal

        open_count = actors.select { |actor|
          context = context(percentage, :feature, actor)
          subject.open?(context)
        }.size

        expect(open_count).to be_within(margin_of_error).of(expected_open_count)
      end
    end
  end
end
