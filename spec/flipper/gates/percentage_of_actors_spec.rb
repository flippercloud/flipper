require 'helper'
require 'flipper/instrumenters/memory'

describe Flipper::Gates::PercentageOfActors do
  let(:adapter) { double('Adapter', :read => nil) }
  let(:feature) { double('Feature', :name => :search, :adapter => adapter) }
  let(:instrumenter) { Flipper::Instrumenters::Memory.new }

  subject {
    described_class.new(feature, :instrumenter => instrumenter)
  }

  describe "instrumentation" do
    it "is recorded for open" do
      thing = Struct.new(:flipper_id).new('22')
      subject.open?(thing)

      event = instrumenter.events.last
      event.should_not be_nil
      event.name.should eq('gate_operation.flipper')
      event.payload.should eq({
        :thing => thing,
        :operation => :open?,
        :result => false,
        :gate_name => :percentage_of_actors,
        :feature_name => :search,
      })
    end
  end

  describe "#description" do
    context "when enabled" do
      before do
        adapter.stub(:read => 22)
      end

      it "returns text" do
        subject.description.should eq('22% of actors')
      end
    end

    context "when disabled" do
      before do
        adapter.stub(:read => nil)
      end

      it "returns disabled" do
        subject.description.should eq('disabled')
      end
    end
  end

  describe "#open?" do
    context "when compared against two features" do
      let(:percentage) { 0.05 }
      let(:number_of_actors) { 100 }

      let(:actors) {
        (1..number_of_actors).map { |n|
          Struct.new(:flipper_id).new(n)
        }
      }

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

      before do
        percentage_as_integer = percentage * 100
        adapter.stub(:read => percentage_as_integer)
      end

      it "does not enable both features for same set of actors" do
        feature_one_enabled_actors.should_not eq(feature_two_enabled_actors)
      end

      it "enables feature for accurate number of actors for each feature" do
        margin_of_error = 0.02 * number_of_actors # 2 percent margin of error
        expected_enabled_size = number_of_actors * percentage

        [
          feature_one_enabled_actors.size,
          feature_two_enabled_actors.size,
        ].each do |actual_enabled_size|
          actual_enabled_size.should be_within(margin_of_error).of(expected_enabled_size)
        end
      end
    end
  end
end
