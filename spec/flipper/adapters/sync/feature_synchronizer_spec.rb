require "helper"
require "flipper/adapters/memory"
require "flipper/adapters/operation_logger"
require "flipper/adapters/sync/feature_synchronizer"

RSpec.describe Flipper::Adapters::Sync::FeatureSynchronizer do
  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:feature) { Flipper::Feature.new(:search, adapter) }

  context "when remote disabled" do
    let(:remote) { Flipper::GateValues.new({}) }

    it "does nothing if local is disabled" do
      feature.disable
      described_class.new(feature, feature.gate_values, remote).call
      expect(adapter.get(feature).fetch(:boolean)).to be(nil)
    end

    it "disables if local is enabled" do
      feature.enable
      described_class.new(feature, feature.gate_values, remote).call
      expect(adapter.get(feature).fetch(:boolean)).to be(nil)
    end
  end

  context "when remote boolean enabled" do
    let(:remote) { Flipper::GateValues.new(boolean: true) }

    it "does nothing if local boolean enabled" do
      feature.enable
      described_class.new(feature, feature.gate_values, remote).call
      expect(feature.boolean_value).to be(true)
    end

    it "enables if local is disabled" do
      feature.disable
      described_class.new(feature, feature.gate_values, remote).call
      expect(feature.boolean_value).to be(true)
    end
  end

  context "when conditionally enabled" do
    it "adds remotely added actors" do
      remote = Flipper::GateValues.new(actors: Set["1", "2"])
      feature.enable_actor(Flipper::Actor.new("1"))
      described_class.new(feature, feature.gate_values, remote).call
      expect(feature.actors_value).to eq(Set["1", "2"])
    end

    it "removes remotely removed actors" do
      remote = Flipper::GateValues.new(actors: Set["1"])
      feature.enable_actor(Flipper::Actor.new("1"))
      feature.enable_actor(Flipper::Actor.new("2"))
      described_class.new(feature, feature.gate_values, remote).call
      expect(feature.actors_value).to eq(Set["1"])
    end

    it "adds remotely added groups" do
      remote = Flipper::GateValues.new(actors: Set["staff", "early_access"])
      feature.enable_group(:staff)
      described_class.new(feature, feature.gate_values, remote).call
      expect(feature.actors_value).to eq(Set["staff", "early_access"])
    end

    it "removes remotely removed groups" do
      remote = Flipper::GateValues.new(actors: Set["staff"])
      feature.enable_group(:staff)
      feature.enable_group(:early_access)
      described_class.new(feature, feature.gate_values, remote).call
      expect(feature.actors_value).to eq(Set["staff"])
    end

    it "updates percentage of actors when remote is updated" do
      remote = Flipper::GateValues.new(percentage_of_actors: 25)
      feature.enable_percentage_of_actors(10)
      described_class.new(feature, feature.gate_values, remote).call
      expect(feature.percentage_of_actors_value).to be(25)
    end

    it "updates percentage of time when remote is updated" do
      remote = Flipper::GateValues.new(percentage_of_time: 25)
      feature.enable_percentage_of_time(10)
      described_class.new(feature, feature.gate_values, remote).call
      expect(feature.percentage_of_time_value).to be(25)
    end
  end
end
