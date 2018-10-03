require "helper"
require "flipper/adapters/memory"
require "flipper/adapters/operation_logger"
require "flipper/adapters/sync/feature_synchronizer"
require "flipper/adapters/v2/memory"
require "flipper/adapters/v2/operation_logger"

RSpec.describe Flipper::Adapters::Sync::FeatureSynchronizer do
  [
    [:v1, -> { Flipper::Adapters::OperationLogger.new Flipper::Adapters::Memory.new }],
    [:v2, -> { Flipper::Adapters::V2::OperationLogger.new Flipper::Adapters::V2::Memory.new }],
  ].each do |(version, adapter_builder)|
    context "#{version.upcase} #{adapter_builder.call.adapter.name}" do
      let(:adapter) { adapter_builder.call }
      let(:flipper) { Flipper.new(adapter) }
      let(:feature) { flipper[:search] }

      context "when remote disabled" do
        let(:remote) { Flipper::GateValues.new({}) }

        it "does nothing if local is disabled" do
          feature.disable
          adapter.reset

          described_class.new(feature, feature.gate_values, remote).call

          expect(gate_values_for_feature(feature).fetch(:boolean)).to be(nil)
          expect_no_enable_or_disable
        end

        it "disables if local is enabled" do
          feature.enable
          adapter.reset

          described_class.new(feature, feature.gate_values, remote).call

          expect(gate_values_for_feature(feature).fetch(:boolean)).to be(nil)
          expect_only_clear
        end
      end

      context "when remote boolean enabled" do
        let(:remote) { Flipper::GateValues.new(boolean: true) }

        it "does nothing if local boolean enabled" do
          feature.enable
          adapter.reset

          described_class.new(feature, feature.gate_values, remote).call
          expect(feature.boolean_value).to be(true)
          expect_no_enable_or_disable
        end

        it "enables if local is disabled" do
          feature.disable
          adapter.reset

          described_class.new(feature, feature.gate_values, remote).call
          expect(feature.boolean_value).to be(true)
          expect_only_enable
        end
      end

      context "when remote conditionally enabled" do
        it "disables feature locally and syncs conditional enablements" do
          feature.enable
          adapter.reset
          remote_gate_values_hash = {
            boolean: nil,
            actors: Set["1"],
            groups: Set["staff"],
            percentage_of_time: 10,
            percentage_of_actors: 15,
          }
          remote = Flipper::GateValues.new(remote_gate_values_hash)

          described_class.new(feature, feature.gate_values, remote).call

          local_gate_values_hash = gate_values_for_feature(feature)
          expect(local_gate_values_hash.fetch(:boolean)).to be(nil)
          expect(local_gate_values_hash.fetch(:actors)).to eq(Set["1"])
          expect(local_gate_values_hash.fetch(:groups)).to eq(Set["staff"])
          expect(local_gate_values_hash.fetch(:percentage_of_time)).to eq("10")
          expect(local_gate_values_hash.fetch(:percentage_of_actors)).to eq("15")
        end

        it "adds remotely added actors" do
          remote = Flipper::GateValues.new(actors: Set["1", "2"])
          feature.enable_actor(Flipper::Actor.new("1"))
          adapter.reset

          described_class.new(feature, feature.gate_values, remote).call

          expect(feature.actors_value).to eq(Set["1", "2"])
          expect_only_enable
        end

        it "removes remotely removed actors" do
          remote = Flipper::GateValues.new(actors: Set["1"])
          feature.enable_actor(Flipper::Actor.new("1"))
          feature.enable_actor(Flipper::Actor.new("2"))
          adapter.reset

          described_class.new(feature, feature.gate_values, remote).call

          expect(feature.actors_value).to eq(Set["1"])
          expect_only_disable
        end

        it "does nothing to actors if in sync" do
          remote = Flipper::GateValues.new(actors: Set["1"])
          feature.enable_actor(Flipper::Actor.new("1"))
          adapter.reset

          described_class.new(feature, feature.gate_values, remote).call

          expect(feature.actors_value).to eq(Set["1"])
          expect_no_enable_or_disable
        end

        it "adds remotely added groups" do
          remote = Flipper::GateValues.new(groups: Set["staff", "early_access"])
          feature.enable_group(:staff)
          adapter.reset

          described_class.new(feature, feature.gate_values, remote).call

          expect(feature.groups_value).to eq(Set["staff", "early_access"])
          expect_only_enable
        end

        it "removes remotely removed groups" do
          remote = Flipper::GateValues.new(groups: Set["staff"])
          feature.enable_group(:staff)
          feature.enable_group(:early_access)
          adapter.reset

          described_class.new(feature, feature.gate_values, remote).call

          expect(feature.groups_value).to eq(Set["staff"])
          expect_only_disable
        end

        it "does nothing if groups in sync" do
          remote = Flipper::GateValues.new(groups: Set["staff"])
          feature.enable_group(:staff)
          adapter.reset

          described_class.new(feature, feature.gate_values, remote).call

          expect(feature.groups_value).to eq(Set["staff"])
          expect_no_enable_or_disable
        end

        it "updates percentage of actors when remote is updated" do
          remote = Flipper::GateValues.new(percentage_of_actors: 25)
          feature.enable_percentage_of_actors(10)
          adapter.reset

          described_class.new(feature, feature.gate_values, remote).call

          expect(feature.percentage_of_actors_value).to be(25)
          expect_only_enable
        end

        it "does nothing if local percentage of actors matches remote" do
          remote = Flipper::GateValues.new(percentage_of_actors: 25)
          feature.enable_percentage_of_actors(25)
          adapter.reset

          described_class.new(feature, feature.gate_values, remote).call

          expect(feature.percentage_of_actors_value).to be(25)
          expect_no_enable_or_disable
        end

        it "updates percentage of time when remote is updated" do
          remote = Flipper::GateValues.new(percentage_of_time: 25)
          feature.enable_percentage_of_time(10)
          adapter.reset

          described_class.new(feature, feature.gate_values, remote).call

          expect(feature.percentage_of_time_value).to be(25)
          expect_only_enable
        end

        it "does nothing if local percentage of time matches remote" do
          remote = Flipper::GateValues.new(percentage_of_time: 25)
          feature.enable_percentage_of_time(25)
          adapter.reset

          described_class.new(feature, feature.gate_values, remote).call

          expect(feature.percentage_of_time_value).to be(25)
          expect_no_enable_or_disable
        end
      end
    end
  end

  def expect_no_enable_or_disable
    case adapter.version
    when Flipper::Adapter::V1
      expect(adapter.count(:enable)).to be(0)
      expect(adapter.count(:disable)).to be(0)
    when Flipper::Adapter::V2
      expect(adapter.count(:set)).to be(0)
    else
      raise 'unsupported adapter version'
    end
  end

  def expect_only_enable
    case adapter.version
    when Flipper::Adapter::V1
      expect(adapter.count(:enable)).to be(1)
      expect(adapter.count(:disable)).to be(0)
    when Flipper::Adapter::V2
      expect(adapter.count(:set)).to be(1)
    else
      raise 'unsupported adapter version'
    end
  end

  def expect_only_disable
    case adapter.version
    when Flipper::Adapter::V1
      expect(adapter.count(:enable)).to be(0)
      expect(adapter.count(:disable)).to be(1)
    when Flipper::Adapter::V2
      expect(adapter.count(:set)).to be(1)
    else
      raise 'unsupported adapter version'
    end
  end

  def expect_only_clear
    case adapter.version
    when Flipper::Adapter::V1
      expect(adapter.count(:enable)).to be(0)
      expect(adapter.count(:disable)).to be(0)
      expect(adapter.count(:clear)).to be(1)
    when Flipper::Adapter::V2
      expect(adapter.count(:set)).to be(1)
    else
      raise 'unsupported adapter version'
    end
  end

  def gate_values_for_feature(feature)
    Flipper::Storage.new(adapter).get(feature)
  end
end
