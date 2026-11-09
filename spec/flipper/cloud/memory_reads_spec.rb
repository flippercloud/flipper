require "active_support"
require "active_support/cache"
require "flipper/adapters/active_support_cache_store"
require "flipper/cloud"
require "flipper/adapters/operation_logger"
require "flipper/instrumenters/memory"

# A Cloud instance that serves reads from Memory, the way
# Flipper::Cloud.set_default builds one. Each "process" gets its own Memory and
# poller, and every process shares one local adapter (think one database).
RSpec.describe "Flipper::Cloud memory reads" do
  let(:database) { Flipper::Adapters::Memory.new }
  let(:remote) { Flipper::Adapters::Memory.new }
  let(:instrumenter) { Flipper::Instrumenters::Memory.new }
  let(:url) { "https://www.flippercloud.io/adapter/features?exclude_gate_names=true" }

  def version(number)
    Flipper::SyncVersion.new("scope", number)
  end

  # Sets what Cloud returns on the next poll.
  def cloud_has(number, enabled)
    remote.features.each { |key| remote.remove(Flipper::Feature.new(key, remote)) }
    Flipper.new(remote).enable(:search) if enabled
    Flipper.new(remote).add(:search)
    remote.sync_version = version(number)
  end

  # Returns the Cloud DSL, its poller and its memory.
  def start_process(sync_secret: nil)
    flipper_configuration = Flipper::Configuration.new
    flipper_configuration.adapter { Flipper::Adapters::OperationLogger.new(database) }
    yield flipper_configuration if block_given?
    memory = Flipper::Adapters::Memory.new

    configuration = Flipper::Cloud::Configuration.new(
      token: "asdf",
      sync_secret: sync_secret,
      instrumenter: instrumenter,
      telemetry_enabled: false,
      memory: memory,
      adapter_builder: flipper_configuration,
    )
    poller = Flipper::Poller.new(remote_adapter: remote, shutdown_automatically: false)
    allow(poller).to receive(:start)
    allow(configuration).to receive(:poller).and_return(poller)
    [Flipper::Cloud::DSL.new(configuration), poller, memory]
  end

  before do
    Flipper.new(database).add(:search)
    cloud_has(1, false)
  end

  it "reads from memory without querying the local adapter" do
    cloud, poller = start_process
    cloud_has(2, true)
    poller.sync
    expect(cloud.enabled?(:search)).to be(true)

    store = cloud.adapter.adapter.local.adapter.remote
    expect(store).to be_a(Flipper::Adapters::OperationLogger)
    store.reset
    10.times { cloud.enabled?(:search) }
    cloud.preload_all
    expect(store.operations).to be_empty
  end

  it "syncs Cloud's flags into the local adapter and memory" do
    cloud, poller = start_process
    cloud_has(2, true)
    poller.sync

    expect(cloud.enabled?(:search)).to be(true)
    expect(database.get_all["search"][:boolean]).to eq("true")
    expect(database.sync_version).to eq(version(2))
  end

  it "writes explicit changes to Cloud, the local adapter and memory" do
    cloud, _poller = start_process
    stub_request(:post, "https://www.flippercloud.io/adapter/features").to_return(status: 200, body: "{}")
    stub = stub_request(:post, "https://www.flippercloud.io/adapter/features/search/boolean").
      to_return(status: 200, body: "{}")

    cloud.enable(:search)

    expect(stub).to have_been_requested
    expect(database.get_all["search"][:boolean]).to eq("true")
    expect(cloud.enabled?(:search)).to be(true)
  end

  # Flipper::Cloud's version check has to see the version every process
  # shares, not this process's memory, or a process that is behind would write
  # older flags over newer ones.
  it "never writes a stale poll over newer flags another process synced" do
    behind, behind_poller = start_process
    ahead, ahead_poller = start_process

    cloud_has(3, true)
    ahead_poller.sync
    expect(ahead.enabled?(:search)).to be(true)

    cloud_has(2, false) # an older cached response
    behind_poller.sync

    expect(behind.enabled?(:search)).to be(true)
    expect(database.get_all["search"][:boolean]).to eq("true")
    expect(database.sync_version).to eq(version(3))
    expect(instrumenter.events_by_name("synchronizer_stale.flipper").size).to eq(1)
  end

  context "when the local adapter is down" do
    it "serves new flags from memory and writes them once it is back" do
      cloud, poller = start_process
      allow(database).to receive(:enable).and_raise("database down")
      allow(database).to receive(:get_all).and_raise("database down")
      cloud_has(2, true)
      poller.sync

      expect(cloud.enabled?(:search)).to be(true)
      expect(instrumenter.events_by_name("synchronizer_exception.flipper").size).to eq(1)

      allow(database).to receive(:enable).and_call_original
      allow(database).to receive(:get_all).and_call_original
      poller.sync
      expect(cloud.enabled?(:search)).to be(true)
      expect(database.get_all["search"][:boolean]).to eq("true")
    end

    it "recovers a sync that failed partway" do
      Flipper.new(database).add(:analytics)
      cloud, poller, memory = start_process
      cloud_has(2, true)
      Flipper.new(remote).enable(:analytics)
      allow(database).to receive(:enable).and_wrap_original do |original, feature, *args|
        raise "database down" if feature.key == "search"
        original.call(feature, *args)
      end
      poller.sync

      expect(cloud.enabled?(:search)).to be(true)
      expect(cloud.enabled?(:analytics)).to be(true)
      expect(database.get_all["search"][:boolean]).to be_nil

      allow(database).to receive(:enable).and_call_original
      poller.sync
      cloud.enabled?(:search)
      expect(database.get_all).to eq(memory.get_all)
    end

    it "fills memory from Cloud when it is down at boot" do
      allow(database).to receive(:get_all).and_raise("database down")
      allow(database).to receive(:features).and_raise("database down")
      cloud_has(2, true)

      cloud, _poller = start_process
      expect(cloud.enabled?(:search)).to be(true)
    end
  end

  it "fills memory once from the local adapter" do
    Flipper.new(database).enable(:search)
    cloud, _poller = start_process

    expect(cloud.enabled?(:search)).to be(true)
  end

  it "keeps adapters added with use around memory" do
    cloud, poller = start_process do |config|
      config.use Flipper::Adapters::Strict, :raise
    end
    poller.sync

    expect(cloud.enabled?(:search)).to be(false)
    expect { cloud.enabled?(:typo) }.to raise_error(Flipper::Adapters::Strict::NotFound)
  end

  # Regression: syncs skipped use wrappers, so a cache wrapper served stale flags.
  # Found by /qa on 2026-11-08
  it "sends syncs through adapters added with use" do
    cache = ActiveSupport::Cache::MemoryStore.new
    cloud, poller = start_process do |config|
      config.use Flipper::Adapters::ActiveSupportCacheStore, cache, 60
    end
    poller.sync
    expect(cloud.enabled?(:search)).to be(false)

    cloud_has(2, true)
    poller.sync
    expect(cloud.enabled?(:search)).to be(true)
  end

  it "takes newer stored flags from storage, not a cache in front of it" do
    cache = ActiveSupport::Cache::MemoryStore.new
    behind, behind_poller = start_process do |config|
      config.use Flipper::Adapters::ActiveSupportCacheStore, cache, 60
    end
    ahead, ahead_poller = start_process
    behind_poller.sync
    behind.adapter.adapter.local.adapter.get_all # fill the cache

    cloud_has(3, true)
    ahead_poller.sync
    expect(ahead.enabled?(:search)).to be(true)

    cloud_has(2, false) # an older cached response
    behind_poller.sync
    expect(behind.enabled?(:search)).to be(true)
  end

  context "webhook mode" do
    let(:now) { [100] }

    def freeze_clock
      allow(Process).to receive(:clock_gettime).and_call_original
      allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC, :second) { now.first }
    end

    def stub_cloud(number, enabled)
      body = JSON.generate(features: [{ key: "search", gates: [{ key: "boolean", value: enabled }] }])
      stub_request(:get, %r{\Ahttps://www\.flippercloud\.io/adapter/features\?_cb=\d+&exclude_gate_names=true\z}).
        to_return(status: 200, body: body, headers: { "flipper-sync-version" => number.to_s })
    end

    it "syncs the local adapter and memory with one request" do
      cloud, _poller = start_process(sync_secret: "secret")
      stub = stub_cloud(5, true)

      cloud.sync(cache_bust: true)

      expect(stub).to have_been_requested.once
      expect(cloud.enabled?(:search)).to be(true)
      expect(database.get_all["search"][:boolean]).to eq("true")
      expect(database.sync_version.number).to eq(5)
    end

    it "updates memory and raises when the local adapter is down" do
      cloud, _poller = start_process(sync_secret: "secret")
      stub_cloud(5, true)
      allow(database).to receive(:enable).and_raise("database down")

      expect { cloud.sync(cache_bust: true) }.to raise_error("database down")
      expect(cloud.enabled?(:search)).to be(true)
    end

    it "reloads memory from the local adapter so other processes see a webhook" do
      freeze_clock
      receiver, _poller = start_process(sync_secret: "secret")
      other, _other_poller = start_process(sync_secret: "secret")
      expect(other.enabled?(:search)).to be(false)

      stub_cloud(5, true)
      receiver.sync(cache_bust: true)
      expect(receiver.enabled?(:search)).to be(true)
      expect(other.enabled?(:search)).to be(false)

      now[0] = 110
      expect(other.enabled?(:search)).to be(true)
    end

    it "keeps flags when reloading from a Memory local adapter" do
      freeze_clock
      cloud, poller = start_process(sync_secret: "secret") do |config|
        config.adapter { Flipper::Adapters::Memory.new }
      end
      cloud_has(2, true)
      poller.sync
      expect(cloud.enabled?(:search)).to be(true)

      now[0] = 110
      expect(cloud.enabled?(:search)).to be(true)
    end
  end
end
