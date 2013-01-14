require 'helper'
require 'flipper/instrumentors/memory'

describe Flipper::Gates::PercentageOfActors do
  let(:percentage) { 5 }
  let(:adapter) { double('Adapter', :read => percentage) }
  let(:feature) { double('Feature', :name => :search, :adapter => adapter) }
  let(:instrumentor) { Flipper::Instrumentors::Memory.new }

  describe "instrumentation" do

    subject {
      described_class.new(feature, :instrumentor => instrumentor)
    }

    it "is recorded for open" do
      thing = Struct.new(:flipper_id).new('22')
      subject.open?(thing)

      event = instrumentor.events.last
      event.should_not be_nil
      event.name.should eq('open.percentage_of_actors.gate.flipper')
      event.payload.should eq({
        :thing => thing,
      })
    end
  end

  describe "#open?" do
    context "with a unique set of actors" do
      let(:total_actors) { 100 }
      let(:margin_of_error) { 0.02 * total_actors }
      let(:actors) do
        (1..total_actors).map { |n| Struct.new(:flipper_id).new(n) }
      end

      context "when compared against two features" do
        let(:feature_one_enabled_actors) do
          feature_one = double('Feature', :name => :name_one, :adapter => adapter)
          gate = described_class.new(feature_one)
          actors.select { |actor| gate.open? actor }
        end

        let(:feature_two_enabled_actors) do
          feature_two = double('Feature', :name => :name_two, :adapter => adapter)
          gate = described_class.new(feature_two)
          actors.select { |actor| gate.open? actor }
        end

        it "returns unique sets" do
          feature_one_enabled_actors.should_not eq(feature_two_enabled_actors)
        end

        it "returns an accurate percentage of actors" do
          expected_actors = total_actors * percentage * 0.01
          feature_one_enabled_actors.size.should(
            be_within(margin_of_error).of(expected_actors)
          )
          feature_two_enabled_actors.size.should(
            be_within(margin_of_error).of(expected_actors)
          )
        end
      end
    end
  end
end
