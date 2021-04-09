require 'helper'
require 'redis'
require 'rollout'
require 'flipper/adapters/rollout'
require 'flipper/spec/shared_adapter_specs'

RSpec.describe Flipper::Adapters::Rollout do
  let(:redis) { Redis.new }
  let(:rollout) { Rollout.new(redis) }
  let(:source_adapter) { described_class.new(rollout) }
  let(:source_flipper) { Flipper.new(source_adapter) }
  let(:destination_adapter) { Flipper::Adapters::Memory.new }
  let(:destination_flipper) { Flipper.new(destination_adapter) }

  before do
    begin
      redis.flushdb
    rescue Redis::CannotConnectError
      ENV['CI'] ? raise : skip('Redis not available')
    end
  end

  describe '#name' do
    it 'has name that is a symbol' do
      expect(source_adapter.name).not_to be_nil
      expect(source_adapter.name).to be_instance_of(Symbol)
    end
  end

  describe '#get' do
    it 'returns hash of gate data' do
      rollout.activate_user(:chat, Struct.new(:id).new(1))
      rollout.activate_percentage(:chat, 20)
      rollout.activate_group(:chat, :admins)
      feature = source_flipper[:chat]
      expected = {
        boolean: nil,
        groups: Set.new([:admins]),
        actors: Set.new(["1"]),
        percentage_of_actors: 20.0,
        percentage_of_time: nil,
      }
      expect(source_adapter.get(feature)).to eq(expected)
    end

    it 'returns fully flipper enabled for fully rollout activated' do
      rollout.activate(:chat)
      feature = source_flipper[:chat]
      expected = {
        boolean: true,
        groups: Set.new,
        actors: Set.new,
        percentage_of_actors: nil,
        percentage_of_time: nil,
      }
      expect(source_adapter.get(feature)).to eq(expected)
    end

    it 'returns fully flipper enabled for fully rollout activated with user/group' do
      rollout.activate_user(:chat, Struct.new(:id).new(1))
      rollout.activate_group(:chat, :admins)
      rollout.activate(:chat)
      feature = source_flipper[:chat]
      expected = {
        boolean: true,
        groups: Set.new,
        actors: Set.new,
        percentage_of_actors: nil,
        percentage_of_time: nil,
      }
      expect(source_adapter.get(feature)).to eq(expected)
    end

    it 'returns default hash of gate data for feature not existing in rollout' do
      feature = source_flipper[:chat]
      expect(source_adapter.get(feature)).to eq(source_adapter.default_config)
    end
  end

  describe '#features' do
    it 'returns all feature keys' do
      rollout.activate(:chat)
      rollout.activate(:messaging)
      rollout.activate(:push_notifications)
      expect(source_adapter.features).to match_array([:chat, :messaging, :push_notifications])
    end
  end

  it 'can have one feature imported' do
    rollout.activate(:search)
    destination_flipper.import(source_flipper)
    expect(destination_flipper.features.map(&:key)).to eq(["search"])
  end

  it 'can have multiple features imported' do
    rollout.activate(:yep)
    rollout.activate_group(:preview_features, :developers)
    rollout.activate_group(:preview_features, :marketers)
    rollout.activate_group(:preview_features, :company)
    rollout.activate_group(:preview_features, :early_access)
    rollout.activate_user(:preview_features, Struct.new(:id).new(1))
    rollout.activate_user(:preview_features, Struct.new(:id).new(2))
    rollout.activate_user(:preview_features, Struct.new(:id).new(3))
    rollout.activate_percentage(:issues_next, 25)

    destination_flipper.import(source_flipper)

    feature = destination_flipper[:yep]
    expect(feature.boolean_value).to eq(true)

    feature = destination_flipper[:preview_features]
    expect(feature.boolean_value).to be(false)
    expect(feature.actors_value).to eq(Set['1', '2', '3'])
    expected_groups = Set['developers', 'marketers', 'company', 'early_access']
    expect(feature.groups_value).to eq(expected_groups)
    expect(feature.percentage_of_actors_value).to be(0)

    feature = destination_flipper[:issues_next]
    expect(feature.boolean_value).to eq(false)
    expect(feature.actors_value).to eq(Set.new)
    expect(feature.groups_value).to eq(Set.new)
    expect(feature.percentage_of_actors_value).to be(25.0)

    feature = destination_flipper[:verbose_logging]
    expect(feature.boolean_value).to eq(false)
    expect(feature.actors_value).to eq(Set.new)
    expect(feature.groups_value).to eq(Set.new)
    expect(feature.percentage_of_actors_value).to be(0)
  end

  describe 'unsupported methods' do
    it 'raises on add' do
      expect { source_adapter.add(:feature) }
        .to raise_error(Flipper::Adapters::Rollout::AdapterMethodNotSupportedError)
    end

    it 'raises on remove' do
      expect { source_adapter.remove(:feature) }
        .to raise_error(Flipper::Adapters::Rollout::AdapterMethodNotSupportedError)
    end

    it 'raises on clear' do
      expect { source_adapter.clear(:feature) }
        .to raise_error(Flipper::Adapters::Rollout::AdapterMethodNotSupportedError)
    end

    it 'raises on enable' do
      expect { source_adapter.enable(:feature, :gate, :thing) }
        .to raise_error(Flipper::Adapters::Rollout::AdapterMethodNotSupportedError)
    end

    it 'raises on disable' do
      expect { source_adapter.disable(:feature, :gate, :thing) }
        .to raise_error(Flipper::Adapters::Rollout::AdapterMethodNotSupportedError)
    end

    it 'raises on import' do
      expect { source_adapter.import(:source_adapter) }
        .to raise_error(Flipper::Adapters::Rollout::AdapterMethodNotSupportedError)
    end
  end
end
