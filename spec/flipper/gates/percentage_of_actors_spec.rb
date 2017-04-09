require 'helper'

RSpec.describe Flipper::Gates::PercentageOfActors do
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
    context 'when compared against two features' do
      let(:percentage) { 0.05 }
      let(:percentage_as_integer) { percentage * 100 }
      let(:number_of_actors) { 100 }

      let(:actors) do
        (1..number_of_actors).map { |n| Flipper::Actor.new(n) }
      end

      let(:feature_one_enabled_actors) do
        gate = described_class.new
        actors.select { |actor| gate.open? context(percentage_as_integer, :name_one, actor) }
      end

      let(:feature_two_enabled_actors) do
        gate = described_class.new
        actors.select { |actor| gate.open? context(percentage_as_integer, :name_two, actor) }
      end

      it 'does not enable both features for same set of actors' do
        expect(feature_one_enabled_actors).not_to eq(feature_two_enabled_actors)
      end

      it 'enables feature for accurate number of actors for each feature' do
        margin_of_error = 0.02 * number_of_actors # 2 percent margin of error
        expected_enabled_size = number_of_actors * percentage

        [
          feature_one_enabled_actors.size,
          feature_two_enabled_actors.size,
        ].each do |actual_enabled_size|
          expect(actual_enabled_size).to be_within(margin_of_error).of(expected_enabled_size)
        end
      end
    end
  end
end
