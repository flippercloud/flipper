require 'helper'

RSpec.describe Flipper::Gates::PercentageOfActors do
  let(:feature_name) { :search }

  subject {
    described_class.new
  }

  def context(integer, feature = feature_name)
    Flipper::GateContext.new(
      values: Flipper::GateValues.new({percentage_of_actors: integer}),
      feature_name: feature
    )
  end

  describe "#open?" do
    context "when compared against two features" do
      let(:percentage) { 0.05 }
      let(:percentage_as_integer) { percentage * 100 }
      let(:number_of_actors) { 100 }

      let(:actors) {
        (1..number_of_actors).map { |n| Struct.new(:flipper_id).new(n) }
      }

      let(:feature_one_enabled_actors) do
        gate = described_class.new
        actors.select { |actor| gate.open? actor, context(percentage_as_integer) }
      end

      let(:feature_two_enabled_actors) do
        gate = described_class.new
        actors.select { |actor| gate.open? actor, context(percentage_as_integer, feature_name: :name_two) }
      end

      it "does not enable both features for same set of actors" do
        expect(feature_one_enabled_actors).not_to eq(feature_two_enabled_actors)
      end

      it "enables feature for accurate number of actors for each feature" do
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
