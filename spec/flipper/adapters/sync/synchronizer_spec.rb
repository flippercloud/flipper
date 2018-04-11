require "helper"
require "flipper/adapters/memory"
require "flipper/instrumenters/memory"
require "flipper/adapters/sync/synchronizer"

RSpec.describe Flipper::Adapters::Sync::Synchronizer do
  let(:local) { Flipper::Adapters::Memory.new }
  let(:remote) { Flipper::Adapters::Memory.new }
  let(:local_flipper) { Flipper.new(local) }
  let(:remote_flipper) { Flipper.new(remote) }
  let(:instrumenter) { Flipper::Instrumenters::Memory.new }

  subject { described_class.new(local, remote, instrumenter: instrumenter) }

  it "instruments call" do
    subject.call
    expect(instrumenter.events_by_name("synchronizer_exception.flipper").size).to be(0)

    events = instrumenter.events_by_name("synchronizer_call.flipper")
    expect(events.size).to be(1)
  end

  it "does not raise, but instruments exceptions for visibility" do
    exception = StandardError.new
    expect(remote).to receive(:get_all).and_raise(exception)

    expect { subject.call }.not_to raise_error

    events = instrumenter.events_by_name("synchronizer_exception.flipper")
    expect(events.size).to be(1)

    event = events[0]
    expect(event.payload[:exception]).to eq(exception)
  end

  describe '#call' do
    it 'returns nothing' do
      expect(subject.call).to be(nil)
      expect(instrumenter.events_by_name("synchronizer_exception.flipper").size).to be(0)
    end

    it 'can sync feature from one adapter to another' do
      remote_flipper.enable(:search)

      subject.call
      expect(instrumenter.events_by_name("synchronizer_exception.flipper").size).to be(0)

      expect(local_flipper[:search].boolean_value).to eq(true)
      expect(local_flipper.features.map(&:key).sort).to eq(%w(search))
    end

    it 'can sync features that have been added but their state is off' do
      remote_flipper.add(:search)

      subject.call
      expect(instrumenter.events_by_name("synchronizer_exception.flipper").size).to be(0)

      expect(local_flipper.features.map(&:key)).to eq(["search"])
    end

    it 'can sync multiple features' do
      remote_flipper.enable(:yep)
      remote_flipper.enable_group(:preview_features, :developers)
      remote_flipper.enable_group(:preview_features, :marketers)
      remote_flipper.enable_group(:preview_features, :company)
      remote_flipper.enable_group(:preview_features, :early_access)
      remote_flipper.enable_actor(:preview_features, Flipper::Actor.new('1'))
      remote_flipper.enable_actor(:preview_features, Flipper::Actor.new('2'))
      remote_flipper.enable_actor(:preview_features, Flipper::Actor.new('3'))
      remote_flipper.enable_percentage_of_actors(:issues_next, 25)
      remote_flipper.enable_percentage_of_time(:verbose_logging, 5)

      subject.call
      expect(instrumenter.events_by_name("synchronizer_exception.flipper").size).to be(0)

      feature = local_flipper[:yep]
      expect(feature.boolean_value).to be(true)
      expect(feature.groups_value).to eq(Set[])
      expect(feature.actors_value).to eq(Set[])
      expect(feature.percentage_of_actors_value).to be(0)
      expect(feature.percentage_of_time_value).to be(0)

      feature = local_flipper[:preview_features]
      expect(feature.boolean_value).to be(false)
      expect(feature.actors_value).to eq(Set['1', '2', '3'])
      expected_groups = Set['developers', 'marketers', 'company', 'early_access']
      expect(feature.groups_value).to eq(expected_groups)
      expect(feature.percentage_of_actors_value).to be(0)
      expect(feature.percentage_of_time_value).to be(0)

      feature = local_flipper[:issues_next]
      expect(feature.boolean_value).to eq(false)
      expect(feature.actors_value).to eq(Set.new)
      expect(feature.groups_value).to eq(Set.new)
      expect(feature.percentage_of_actors_value).to be(25)
      expect(feature.percentage_of_time_value).to be(0)

      feature = local_flipper[:verbose_logging]
      expect(feature.boolean_value).to eq(false)
      expect(feature.actors_value).to eq(Set.new)
      expect(feature.groups_value).to eq(Set.new)
      expect(feature.percentage_of_actors_value).to be(0)
      expect(feature.percentage_of_time_value).to be(5)
    end

    it 'wipes existing enablements for adapter' do
      local_flipper.enable(:stats)
      local_flipper.enable_percentage_of_time(:verbose_logging, 5)
      remote_flipper.enable_percentage_of_time(:stats, 5)
      remote_flipper.enable_percentage_of_actors(:verbose_logging, 25)

      subject.call
      expect(instrumenter.events_by_name("synchronizer_exception.flipper").size).to be(0)

      feature = local_flipper[:stats]
      expect(feature.boolean_value).to be(false)
      expect(feature.percentage_of_time_value).to be(5)

      feature = local_flipper[:verbose_logging]
      expect(feature.percentage_of_time_value).to be(0)
      expect(feature.percentage_of_actors_value).to be(25)
    end

    it 'removes locally added features' do
      local_flipper.add(:stats)

      subject.call
      expect(instrumenter.events_by_name("synchronizer_exception.flipper").size).to be(0)

      expect(local_flipper.features.map(&:key)).to eq([])
    end

    it 'disables locally enabled features' do
      local_flipper.enable(:stats)

      subject.call
      expect(instrumenter.events_by_name("synchronizer_exception.flipper").size).to be(0)

      expect(local_flipper[:stats]).to be_off
    end
  end
end
