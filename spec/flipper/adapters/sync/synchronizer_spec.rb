require "flipper/adapters/memory"
require "flipper/adapters/actor_limit"
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

  it "raises errors by default" do
    exception = StandardError.new
    expect(remote).to receive(:get_all).and_raise(exception)

    expect { subject.call }.to raise_error(exception)
  end

  context "when raise disabled" do
    subject do
      options = {
        instrumenter: instrumenter,
        raise: false,
      }
      described_class.new(local, remote, options)
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
  end

  describe '#call' do
    it 'returns nothing' do
      expect(subject.call).to be(nil)
      expect(instrumenter.events_by_name("synchronizer_exception.flipper").size).to be(0)
    end

    it 'syncs each remote feature to local' do
      remote_flipper.enable(:search)
      remote_flipper.enable_percentage_of_time(:logging, 10)

      subject.call
      expect(instrumenter.events_by_name("synchronizer_exception.flipper").size).to be(0)

      expect(local_flipper[:search].boolean_value).to eq(true)
      expect(local_flipper[:logging].percentage_of_time_value).to eq(10)
      expect(local_flipper.features.map(&:key).sort).to eq(%w(logging search))
    end

    it 'adds features in remote that are not in local' do
      remote_flipper.add(:search)

      subject.call
      expect(instrumenter.events_by_name("synchronizer_exception.flipper").size).to be(0)

      expect(local_flipper.features.map(&:key)).to eq(["search"])
    end

    it 'removes features in local that are not in remote' do
      local_flipper.add(:stats)

      subject.call
      expect(instrumenter.events_by_name("synchronizer_exception.flipper").size).to be(0)

      expect(local_flipper.features.map(&:key)).to eq([])
    end

    it 'emits feature_operation.flipper events when syncing' do
      remote_flipper.enable(:search)

      subject.call

      events = instrumenter.events_by_name("feature_operation.flipper")
      enable_events = events.select { |e| e.payload[:operation] == :enable }
      expect(enable_events).not_to be_empty

      feature_names = enable_events.map { |e| e.payload[:feature_name].to_s }
      expect(feature_names).to include("search")
    end

    it 'emits feature_operation.flipper events when adding features' do
      remote_flipper.add(:new_feature)

      subject.call

      events = instrumenter.events_by_name("feature_operation.flipper")
      add_events = events.select { |e| e.payload[:operation] == :add }
      expect(add_events).not_to be_empty

      feature_names = add_events.map { |e| e.payload[:feature_name].to_s }
      expect(feature_names).to include("new_feature")
    end

    it 'emits feature_operation.flipper events when removing features' do
      local_flipper.add(:old_feature)

      subject.call

      events = instrumenter.events_by_name("feature_operation.flipper")
      remove_events = events.select { |e| e.payload[:operation] == :remove }
      expect(remove_events).not_to be_empty

      feature_names = remove_events.map { |e| e.payload[:feature_name].to_s }
      expect(feature_names).to include("old_feature")
    end
  end

  describe 'sync_version gating' do
    it 'skips sync when remote version is not strictly greater than local version' do
      local.set_integer_if_greater(:sync_version, 100)
      allow(remote).to receive(:read_integer).with(:sync_version).and_return(99)
      remote_flipper.enable(:search)

      subject.call

      expect(local_flipper.features.map(&:key)).to eq([])
    end

    it 'skips sync when remote version equals local version' do
      local.set_integer_if_greater(:sync_version, 100)
      allow(remote).to receive(:read_integer).with(:sync_version).and_return(100)
      remote_flipper.enable(:search)

      subject.call

      expect(local_flipper.features.map(&:key)).to eq([])
    end

    it 'syncs and bumps local version when remote version is strictly greater' do
      local.set_integer_if_greater(:sync_version, 99)
      allow(remote).to receive(:read_integer).with(:sync_version).and_return(100)
      remote_flipper.enable(:search)

      subject.call

      expect(local_flipper.features.map(&:key)).to eq(["search"])
      expect(local.read_integer(:sync_version)).to eq(100)
    end

    it 'syncs normally when remote returns nil version (older server)' do
      allow(remote).to receive(:read_integer).with(:sync_version).and_return(nil)
      remote_flipper.enable(:search)

      subject.call

      expect(local_flipper.features.map(&:key)).to eq(["search"])
    end

    it 'syncs normally when local has no stored version yet' do
      allow(remote).to receive(:read_integer).with(:sync_version).and_return(100)
      remote_flipper.enable(:search)

      subject.call

      expect(local_flipper.features.map(&:key)).to eq(["search"])
      expect(local.read_integer(:sync_version)).to eq(100)
    end

    it 'instruments synchronizer_outvoted.flipper when bump_sync_version is rejected' do
      allow(remote).to receive(:read_integer).with(:sync_version).and_return(100)
      remote_flipper.enable(:search)
      allow(local).to receive(:set_integer_if_greater).with(:sync_version, 100).and_return(false)

      subject.call

      events = instrumenter.events_by_name("synchronizer_outvoted.flipper")
      expect(events.size).to eq(1)
      expect(events.first.payload[:remote_version]).to eq(100)
    end

    it 'skips both get_all calls when versions indicate no sync is needed' do
      local.set_integer_if_greater(:sync_version, 100)
      allow(remote).to receive(:read_integer).with(:sync_version).and_return(100)
      expect(local).not_to receive(:get_all)
      expect(remote).not_to receive(:get_all)

      subject.call
    end
  end

  context 'with ActorLimit adapter wrapping local' do
    let(:limit) { 10 }
    let(:limited_local) { Flipper::Adapters::ActorLimit.new(local, limit) }
    let(:limited_local_flipper) { Flipper.new(limited_local) }

    subject { described_class.new(limited_local, remote, instrumenter: instrumenter) }

    it 'syncs actors even when remote has more actors than local limit' do
      # Remote has more actors than local limit allows
      20.times { |i| remote_flipper[:search].enable_actor Flipper::Actor.new("User;#{i}") }

      # This should NOT raise - sync should bypass actor limits
      expect { subject.call }.not_to raise_error

      # All actors should be synced
      expect(limited_local_flipper[:search].actors_value.size).to eq(20)
    end

    it 'syncs new actors added to remote after initial sync' do
      # Initial state: remote has 20 actors, local limit is 10
      20.times { |i| remote_flipper[:search].enable_actor Flipper::Actor.new("User;#{i}") }

      # First sync - should work despite exceeding limit
      subject.call
      expect(limited_local_flipper[:search].actors_value.size).to eq(20)

      # Add a 21st actor to remote (simulating Cloud adding a new actor)
      remote_flipper[:search].enable_actor Flipper::Actor.new("User;20")

      # Sync again - should pick up the new actor
      expect { subject.call }.not_to raise_error
      expect(limited_local_flipper[:search].actors_value.size).to eq(21)
      expect(limited_local_flipper[:search].actors_value).to include("User;20")
    end

    it 'still enforces limit for direct enable operations' do
      # First sync 20 actors from remote
      20.times { |i| remote_flipper[:search].enable_actor Flipper::Actor.new("User;#{i}") }
      subject.call

      # Direct enable should still fail because we're over limit
      expect {
        limited_local_flipper[:search].enable_actor Flipper::Actor.new("User;new")
      }.to raise_error(Flipper::Adapters::ActorLimit::LimitExceeded)
    end
  end
end
