require 'helper'
require 'flipper/adapters/memory'

RSpec.describe Flipper::Adapter do
  it 'can migrate from one adapter to another' do
    actor = Struct.new(:flipper_id).new('22')
    source_adapter = Flipper::Adapters::Memory.new
    destination_adapter = Flipper::Adapters::Memory.new
    source_flipper = Flipper.new(source_adapter)
    destination_flipper = Flipper.new(destination_adapter)

    source_flipper.enable(:search)
    source_flipper.enable_group(:admins, :admins)
    source_flipper.enable_actor(:debug, actor)
    source_flipper.enable_percentage_of_actors(:issues, 25)
    source_flipper.enable_percentage_of_time(:logging, 50)
    source_flipper.enable(:nope)
    source_flipper.disable(:nope)

    destination_flipper.migrate(source_flipper)

    expect(destination_flipper[:search].gate_values).to eq(source_flipper[:search].gate_values)
    expect(destination_flipper[:admin].gate_values).to eq(source_flipper[:admin].gate_values)
    expect(destination_flipper[:debug].gate_values).to eq(source_flipper[:debug].gate_values)
    expect(destination_flipper[:issues].gate_values).to eq(source_flipper[:issues].gate_values)
    expect(destination_flipper[:logging].gate_values).to eq(source_flipper[:logging].gate_values)
    expect(destination_flipper[:nope].gate_values).to eq(source_flipper[:nope].gate_values)
    expected_feature_keys = %w[search admins debug issues logging nope].sort
    expect(destination_flipper.features.map(&:key).sort).to eq(expected_feature_keys)
  end
end
