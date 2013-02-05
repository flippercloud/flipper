require 'helper'
require 'flipper/adapters/memory'
require 'flipper/instrumentation/metriks'

describe Flipper::Instrumentation::MetriksSubscriber do
  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:flipper) {
    Flipper.new(adapter, :instrumenter => ActiveSupport::Notifications)
  }

  let(:user) { user = Struct.new(:flipper_id).new('1') }

  before do
    Metriks::Registry.default.clear
  end

  context "for enabled feature" do
    it "updates feature metrics when calls happen" do
      flipper[:stats].enable(user)
      Metriks.timer("flipper.feature_operation.enable").count.should be(1)

      flipper[:stats].enabled?(user)
      Metriks.timer("flipper.feature_operation.enabled").count.should be(1)
      Metriks.meter("flipper.feature.stats.enabled").count.should be(1)
    end
  end

  context "for disabled feature" do
    it "updates feature metrics when calls happen" do
      flipper[:stats].disable(user)
      Metriks.timer("flipper.feature_operation.disable").count.should be(1)

      flipper[:stats].enabled?(user)
      Metriks.timer("flipper.feature_operation.enabled").count.should be(1)
      Metriks.meter("flipper.feature.stats.disabled").count.should be(1)
    end
  end

  it "updates adapter metrics when calls happen" do
    flipper[:stats].enable(user)
    # one for features and one for actors
    Metriks.timer("flipper.adapter.memory.set_add").count.should be(2)

    flipper[:stats].enabled?(user)
    Metriks.timer("flipper.adapter.memory.read").count.should be(1)
    # one for actors and one for groups
    Metriks.timer("flipper.adapter.memory.set_members").count.should be(2)

    flipper[:stats].disable(user)
    Metriks.timer("flipper.adapter.memory.set_delete").count.should be(1)
  end

  it "updates gate metrics when calls happen" do
    flipper[:stats].enable(user)
    Metriks.timer("flipper.gate_operation.actor.enable").count.should be(1)
    Metriks.timer("flipper.feature.stats.gate_operation.actor.enable").count.should be(1)

    flipper[:stats].enabled?(user)
    Metriks.timer("flipper.gate_operation.boolean.open").count.should be(1)
    Metriks.timer("flipper.feature.stats.gate_operation.boolean.open").count.should be(1)
    Metriks.meter("flipper.feature.stats.gate.actor.open").count.should be(1)
    Metriks.meter("flipper.feature.stats.gate.boolean.closed").count.should be(1)

    flipper[:stats].disable(user)
    Metriks.timer("flipper.gate_operation.actor.disable").count.should be(1)
    Metriks.timer("flipper.feature.stats.gate_operation.actor.disable").count.should be(1)
  end

  # Helper for seeing what is in the metriks registry
  def print_registry_names
    Metriks::Registry.default.each do |name, metric|
      puts name
    end
  end
end
