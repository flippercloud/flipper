require 'helper'
require 'flipper/adapters/memory'

RSpec.describe Flipper::Adapter do
  let(:actor_class) { Struct.new(:flipper_id) }

  let(:source_flipper) { build_flipper }
  let(:destination_flipper) { build_flipper }

  it 'can migrate from one adapter to another' do
    source_flipper.enable(:search)
    destination_flipper.migrate(source_flipper)
    expect(destination_flipper[:search].boolean_value).to eq(true)
    expect(destination_flipper.features.map(&:key).sort).to eq(%w[search])
  end

  it 'can migrate features that exist but are off' do
    feature = source_flipper[:search]
    source_flipper.add(:search)
    destination_flipper.migrate(source_flipper)
    expect(destination_flipper.features.map(&:key)).to eq(["search"])
  end

  it 'can migrate multiple features' do
    source_flipper.enable(:yep)
    source_flipper.enable_group(:preview_features, :developers)
    source_flipper.enable_group(:preview_features, :marketers)
    source_flipper.enable_group(:preview_features, :company)
    source_flipper.enable_group(:preview_features, :early_access)
    source_flipper.enable_actor(:preview_features, actor_class.new('1'))
    source_flipper.enable_actor(:preview_features, actor_class.new('2'))
    source_flipper.enable_actor(:preview_features, actor_class.new('3'))
    source_flipper.enable_percentage_of_actors(:issues_next, 25)
    source_flipper.enable_percentage_of_time(:verbose_logging, 5)

    destination_flipper.migrate(source_flipper)

    feature = destination_flipper[:preview_features]
    expect(feature.boolean_value).to be(false)
    expect(feature.actors_value).to eq(Set['1', '2', '3'])
    expected_groups = Set['developers', 'marketers', 'company', 'early_access']
    expect(feature.groups_value).to eq(expected_groups)
    expect(feature.percentage_of_actors_value).to be(0)
    expect(feature.percentage_of_time_value).to be(0)

    feature = destination_flipper[:issues_next]
    expect(feature.boolean_value).to eq(false)
    expect(feature.actors_value).to eq(Set.new)
    expect(feature.groups_value).to eq(Set.new)
    expect(feature.percentage_of_actors_value).to be(25)
    expect(feature.percentage_of_time_value).to be(0)

    feature = destination_flipper[:verbose_logging]
    expect(feature.boolean_value).to eq(false)
    expect(feature.actors_value).to eq(Set.new)
    expect(feature.groups_value).to eq(Set.new)
    expect(feature.percentage_of_actors_value).to be(0)
    expect(feature.percentage_of_time_value).to be(5)
  end

  it 'wipes existing enablements when migrating' do
    destination_flipper.enable(:stats)
    destination_flipper.enable_percentage_of_time(:verbose_logging, 5)
    source_flipper.enable_percentage_of_time(:stats, 5)
    source_flipper.enable_percentage_of_actors(:verbose_logging, 25)

    destination_flipper.migrate(source_flipper)

    feature = destination_flipper[:stats]
    expect(feature.boolean_value).to be(false)
    expect(feature.percentage_of_time_value).to be(5)

    feature = destination_flipper[:verbose_logging]
    expect(feature.percentage_of_time_value).to be(0)
    expect(feature.percentage_of_actors_value).to be(25)
  end
end
