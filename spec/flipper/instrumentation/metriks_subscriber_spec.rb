require 'helper'
require 'flipper/adapters/memory'
require 'flipper/instrumentation/metriks'

RSpec.describe Flipper::Instrumentation::MetriksSubscriber do
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
      expect(Metriks.timer("flipper.feature_operation.enable").count).to be(1)

      flipper[:stats].enabled?(user)
      expect(Metriks.timer("flipper.feature_operation.enabled").count).to be(1)
      expect(Metriks.meter("flipper.feature.stats.enabled").count).to be(1)
    end
  end

  context "for disabled feature" do
    it "updates feature metrics when calls happen" do
      flipper[:stats].disable(user)
      expect(Metriks.timer("flipper.feature_operation.disable").count).to be(1)

      flipper[:stats].enabled?(user)
      expect(Metriks.timer("flipper.feature_operation.enabled").count).to be(1)
      expect(Metriks.meter("flipper.feature.stats.disabled").count).to be(1)
    end
  end

  it "updates adapter metrics when calls happen" do
    flipper[:stats].enable(user)
    expect(Metriks.timer("flipper.adapter.memory.enable").count).to be(1)

    flipper[:stats].enabled?(user)
    expect(Metriks.timer("flipper.adapter.memory.get").count).to be(1)

    flipper[:stats].disable(user)
    expect(Metriks.timer("flipper.adapter.memory.disable").count).to be(1)
  end

  it "updates gate metrics when calls happen" do
    flipper[:stats].enable(user)
    flipper[:stats].enabled?(user)

    expect(Metriks.timer("flipper.gate_operation.boolean.open").count).to be(1)
    expect(Metriks.timer("flipper.feature.stats.gate_operation.boolean.open").count).to be(1)
    expect(Metriks.meter("flipper.feature.stats.gate.actor.open").count).to be(1)
    expect(Metriks.meter("flipper.feature.stats.gate.boolean.closed").count).to be(1)
  end
end
