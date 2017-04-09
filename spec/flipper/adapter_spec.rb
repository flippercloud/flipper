require 'helper'
require 'flipper/adapters/memory'

RSpec.describe Flipper::Adapter do
  it 'can migrate from one adapter to another' do
    actor = Struct.new(:flipper_id).new('22')
    from_adapter = Flipper::Adapters::Memory.new
    to_adapter = Flipper::Adapters::Memory.new
    from_flipper = Flipper.new(from_adapter)
    to_flipper = Flipper.new(to_adapter)

    from_flipper.enable(:search)
    from_flipper.enable_group(:admins, :admins)
    from_flipper.enable_actor(:debug, actor)
    from_flipper.enable_percentage_of_actors(:issues, 25)
    from_flipper.enable_percentage_of_time(:logging, 50)
    from_flipper.enable(:nope)
    from_flipper.disable(:nope)

    to_flipper.migrate(from_flipper)

    expect(to_flipper[:search].gate_values).to eq(from_flipper[:search].gate_values)
    expect(to_flipper[:admin].gate_values).to eq(from_flipper[:admin].gate_values)
    expect(to_flipper[:debug].gate_values).to eq(from_flipper[:debug].gate_values)
    expect(to_flipper[:issues].gate_values).to eq(from_flipper[:issues].gate_values)
    expect(to_flipper[:logging].gate_values).to eq(from_flipper[:logging].gate_values)
    expect(to_flipper[:nope].gate_values).to eq(from_flipper[:nope].gate_values)
    expected_feature_keys = %w[search admins debug issues logging nope].sort
    expect(to_flipper.features.map(&:key).sort).to eq(expected_feature_keys)
  end
end
