require 'helper'
require 'flipper/adapters/v2/memory'
require 'flipper/adapters/v2/read_only'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::V2::ReadOnly do
  let(:adapter) { Flipper::Adapters::V2::Memory.new }
  let(:flipper) { Flipper.new(adapter) }

  subject { described_class.new(adapter) }

  describe "#name" do
    it "is read_only" do
      expect(subject.name).to be(:read_only)
    end
  end

  let(:actor_class) { Struct.new(:flipper_id) }

  let(:flipper) { Flipper.new(subject) }
  let(:feature) { flipper[:stats] }

  let(:boolean_gate) { feature.gate(:boolean) }
  let(:group_gate)   { feature.gate(:group) }
  let(:actor_gate)   { feature.gate(:actor) }
  let(:actors_gate)  { feature.gate(:percentage_of_actors) }
  let(:time_gate)    { feature.gate(:percentage_of_time) }

  before do
    Flipper.register(:admins) do |actor|
      actor.respond_to?(:admin?) && actor.admin?
    end

    Flipper.register(:early_access) do |actor|
      actor.respond_to?(:early_access?) && actor.early_access?
    end
  end

  after do
    Flipper.unregister_groups
  end

  it "has name that is a symbol" do
    expect(subject.name).not_to be_nil
    expect(subject.name).to be_instance_of(Symbol)
  end

  it "knows version" do
    expect(subject.version).to be(Flipper::Adapter::V2)
  end

  it "has included the flipper adapter module" do
    expect(subject.class.ancestors).to include(Flipper::Adapter)
  end

  it "returns nil when getting missing key" do
    expect(subject.get("foo")).to be(nil)
  end

  it "returns value when getting set key" do
    adapter.set("foo", "bar")
    expect(subject.get("foo")).to eq("bar")
  end
end
