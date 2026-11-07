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
    expect(remote).to receive(:get_all_snapshot).and_raise(exception)

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
      expect(remote).to receive(:get_all_snapshot).and_raise(exception)

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

  describe 'atomic snapshot installation' do
    it 'passes the paired snapshot to the local storage boundary' do
      snapshot = Flipper::Snapshot.new(features: {}, version: 10)
      expect(remote).to receive(:get_all_snapshot).with(cache_bust: false).once.and_return(snapshot)
      expect(local).to receive(:apply_snapshot).with(snapshot, instrumenter: instrumenter).once.and_call_original
      subject.call
    end

    it 'rejects lower revisions without fetching a repair snapshot' do
      local.apply_snapshot(Flipper::Snapshot.new(features: {}, version: 10))
      remote_flipper.enable(:search)
      expect(remote).to receive(:get_all_snapshot).once.and_return(
        Flipper::Snapshot.new(features: remote.get_all, version: 9)
      )
      subject.call
      expect(local.get_all).to eq({})
    end

    it 'reconciles equal revisions after a local edit' do
      local.apply_snapshot(Flipper::Snapshot.new(features: {}, version: 10))
      local_flipper.enable(:local_edit)
      allow(remote).to receive(:get_all_snapshot).and_return(
        Flipper::Snapshot.new(features: {}, version: 10)
      )
      subject.call
      expect(local.get_all).to eq({})
    end

    it 'does not fall back to non-atomic writes after an installation failure' do
      remote_flipper.enable(:search)
      expect(local).to receive(:apply_snapshot).and_raise("installation failed")
      expect(local).not_to receive(:get_all)
      expect { subject.call }.to raise_error("installation failed")
    end

    it 'keeps legacy diff sync for an unsupported local adapter' do
      allow(local).to receive(:supports?).with(:atomic_snapshot_install).and_return(false)
      expect(local).not_to receive(:apply_snapshot)
      remote_flipper.enable(:search)
      subject.call
      expect(local.get_all).to eq(remote.get_all)
    end

    it 'accepts unversioned responses and clears an earlier floor' do
      local.apply_snapshot(Flipper::Snapshot.new(features: {}, version: 10))
      remote_flipper.enable(:search)
      subject.call
      expect(local.get_all).to eq(remote.get_all)
      expect(local.apply_snapshot(Flipper::Snapshot.new(features: {}, version: 1))).to eq(:applied)
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
