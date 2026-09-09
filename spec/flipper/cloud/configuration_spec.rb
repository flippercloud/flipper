require 'flipper/cloud/configuration'
require 'flipper/cloud/dsl'
require 'flipper/adapters/instrumented'
require 'flipper/adapters/sync/interval_synchronizer'
require 'flipper/instrumenters/memory'
require 'timeout'

RSpec.describe Flipper::Cloud::Configuration do
  let(:required_options) do
    { token: "asdf" }
  end

  it "can set token" do
    instance = described_class.new(required_options)
    expect(instance.token).to eq(required_options[:token])
  end

  it "can set token from ENV var" do
    ENV["FLIPPER_CLOUD_TOKEN"] = "from_env"
    instance = described_class.new(required_options.reject { |k, v| k == :token })
    expect(instance.token).to eq("from_env")
  end

  it "can set instrumenter" do
    instrumenter = Object.new
    instance = described_class.new(required_options.merge(instrumenter: instrumenter))
    expect(instance.instrumenter).to be_a(Flipper::Cloud::Telemetry::Instrumenter)
    expect(instance.instrumenter.instrumenter).to be(instrumenter)
  end

  it "can set read_timeout" do
    instance = described_class.new(required_options.merge(read_timeout: 5))
    expect(instance.read_timeout).to eq(5)
  end

  it "can set read_timeout from ENV var" do
    ENV["FLIPPER_CLOUD_READ_TIMEOUT"] = "9"
    instance = described_class.new(required_options.reject { |k, v| k == :read_timeout })
    expect(instance.read_timeout).to eq(9)
  end

  it "can set open_timeout" do
    instance = described_class.new(required_options.merge(open_timeout: 5))
    expect(instance.open_timeout).to eq(5)
  end

  it "can set open_timeout from ENV var" do
    ENV["FLIPPER_CLOUD_OPEN_TIMEOUT"] = "9"
    instance = described_class.new(required_options.reject { |k, v| k == :open_timeout })
    expect(instance.open_timeout).to eq(9)
  end

  it "can set write_timeout" do
    instance = described_class.new(required_options.merge(write_timeout: 5))
    expect(instance.write_timeout).to eq(5)
  end

  it "can set write_timeout from ENV var" do
    ENV["FLIPPER_CLOUD_WRITE_TIMEOUT"] = "9"
    instance = described_class.new(required_options.reject { |k, v| k == :write_timeout })
    expect(instance.write_timeout).to eq(9)
  end

  it "can set sync_interval" do
    instance = described_class.new(required_options.merge(sync_interval: 15))
    expect(instance.sync_interval).to eq(15)
  end

  it "can set sync_interval from ENV var" do
    ENV["FLIPPER_CLOUD_SYNC_INTERVAL"] = "15"
    instance = described_class.new(required_options.reject { |k, v| k == :sync_interval })
    expect(instance.sync_interval).to eq(15)
  end

  it "passes sync_interval into sync adapter" do
    # The initial sync of http to local invokes this web request.
    stub_request(:get, /flippercloud\.io/).to_return(status: 200, body: "{}")

    instance = described_class.new(required_options.merge(sync_interval: 20))
    poller = instance.send(:poller)
    expect(poller.interval).to eq(20)
  end

  it "uses the supplied local adapter without changing its composition" do
    memory = Flipper::Adapters::Memory.new
    persistent = Flipper::Adapters::Memory.new
    mirrored = Flipper::Adapters::DualWrite.new(memory, persistent)
    adapter = Flipper::Adapters::Strict.new(mirrored, :warn)
    Flipper.new(mirrored).add(:search)
    instance = described_class.new(required_options.merge(local_adapter: adapter, sync_secret: "secret"))

    flipper = Flipper::Cloud::DSL.new(instance)
    expect(instance.local_adapter).to be(adapter)
    expect(adapter).to receive(:get).with(flipper[:search]).and_call_original
    expect(flipper.enabled?(:search)).to be(false)
    expect(instance).not_to respond_to(:local_memory)
    expect(instance).not_to respond_to(:local_adapter_memory_backed)
  end

  it "can set debug_output" do
    instance = described_class.new(required_options.merge(debug_output: STDOUT))
    expect(instance.debug_output).to eq(STDOUT)
  end

  it "defaults debug_output to STDOUT if FLIPPER_CLOUD_DEBUG_OUTPUT_STDOUT set to true" do
    ENV["FLIPPER_CLOUD_DEBUG_OUTPUT_STDOUT"] = "true"
    instance = described_class.new(required_options)
    expect(instance.debug_output).to eq(STDOUT)
  end

  it "defaults adapter block" do
    # The initial sync of http to local invokes this web request.
    stub_request(:get, /flippercloud\.io/).to_return(status: 200, body: "{}")

    instance = described_class.new(required_options)
    expect(instance.adapter).to be_instance_of(Flipper::Adapters::DualWrite)
  end

  it "can override adapter block" do
    # The initial sync of http to local invokes this web request.
    stub_request(:get, /flippercloud\.io/).to_return(status: 200, body: "{}")

    instance = described_class.new(required_options)
    instance.adapter do |adapter|
      Flipper::Adapters::Instrumented.new(adapter)
    end
    expect(instance.adapter).to be_instance_of(Flipper::Adapters::Instrumented)
  end

  it "defaults url" do
    instance = described_class.new(required_options.reject { |k, v| k == :url })
    expect(instance.url).to eq("https://www.flippercloud.io/adapter")
  end

  it "can override url using options" do
    options = required_options.merge(url: "https://localhost:5000/adapter")
    instance = described_class.new(options)
    expect(instance.url).to eq("https://localhost:5000/adapter")

    instance = described_class.new(required_options)
    instance.url = "https://localhost:5000/adapter"
    expect(instance.url).to eq("https://localhost:5000/adapter")
  end

  it "requires https url" do
    invalid_urls = [
      "http://localhost:5000/adapter",
      "https://",
      "https:localhost:5000/adapter",
      "https://local host:5000/adapter",
    ]

    invalid_urls.each do |url|
      options = required_options.merge(url: url)
      expect { described_class.new(options) }.to raise_error(ArgumentError, /must use https/)
    end

    instance = described_class.new(required_options)
    expect { instance.url = "http://localhost:5000/adapter" }.to raise_error(ArgumentError, /must use https/)
  end

  it "keeps the validated url immutable" do
    url = String.new("https://localhost:5000/adapter")
    instance = described_class.new(required_options.merge(url: url))

    url.replace("http://localhost:5000/adapter")

    expect(instance.url).to eq("https://localhost:5000/adapter")
    expect(instance.url).to be_frozen
    expect { instance.url.replace("http://localhost:5000/adapter") }.to raise_error(FrozenError)
    expect(instance.send(:http_adapter).client.uri.scheme).to eq("https")
  end

  it "can override URL using ENV var" do
    ENV["FLIPPER_CLOUD_URL"] = "https://example.com"
    instance = described_class.new(required_options.reject { |k, v| k == :url })
    expect(instance.url).to eq("https://example.com")
  end

  it "defaults sync_method to :poll" do
    instance = described_class.new(required_options)

    expect(instance.sync_method).to eq(:poll)
  end

  it "sets sync_method to :webhook if sync_secret provided" do
    instance = described_class.new(required_options.merge({
      sync_secret: "secret",
    }))

    expect(instance.sync_method).to eq(:webhook)
    expect(instance.adapter).to be_instance_of(Flipper::Adapters::DualWrite)
  end

  it "sets sync_method to :poll if sync_secret is empty" do
    instance = described_class.new(required_options.merge({
      sync_secret: "",
    }))

    expect(instance.sync_method).to eq(:poll)
  end

  it "does not treat a whitespace sync_secret as empty" do
    instance = described_class.new(required_options.merge(sync_secret: " "))

    expect(instance.sync_secret).to eq(" ")
    expect(instance.sync_method).to eq(:webhook)
  end

  it "sets sync_method to :webhook if FLIPPER_CLOUD_SYNC_SECRET set" do
    ENV["FLIPPER_CLOUD_SYNC_SECRET"] = "abc"
    instance = described_class.new(required_options)

    expect(instance.sync_method).to eq(:webhook)
    expect(instance.adapter).to be_instance_of(Flipper::Adapters::DualWrite)
  end

  it "sets sync_method to :poll if FLIPPER_CLOUD_SYNC_SECRET is empty" do
    ENV["FLIPPER_CLOUD_SYNC_SECRET"] = ""
    instance = described_class.new(required_options)

    expect(instance.sync_method).to eq(:poll)
  end

  it "can set sync_secret" do
    instance = described_class.new(required_options.merge(sync_secret: "from_config"))
      expect(instance.sync_secret).to eq("from_config")
  end

  it "can override sync_secret using ENV var" do
    ENV["FLIPPER_CLOUD_SYNC_SECRET"] = "from_env"
    instance = described_class.new(required_options.reject { |k, v| k == :sync_secret })
    expect(instance.sync_secret).to eq("from_env")
  end

  it "can sync with cloud" do
    body = JSON.generate({
      "features": [
        {
          "key": "search",
          "state": "on",
          "gates": [
            {
              "key": "boolean",
              "name": "boolean",
              "value": true
            },
            {
              "key": "groups",
              "name": "group",
              "value": []
            },
            {
              "key": "actors",
              "name": "actor",
              "value": []
            },
            {
              "key": "percentage_of_actors",
              "name": "percentage_of_actors",
              "value": 0
            },
            {
              "key": "percentage_of_time",
              "name": "percentage_of_time",
              "value": 0
            }
          ]
        },
        {
          "key": "history",
          "state": "off",
          "gates": [
            {
              "key": "boolean",
              "name": "boolean",
              "value": false
            },
            {
              "key": "groups",
              "name": "group",
              "value": []
            },
            {
              "key": "actors",
              "name": "actor",
              "value": []
            },
            {
              "key": "percentage_of_actors",
              "name": "percentage_of_actors",
              "value": 0
            },
            {
              "key": "percentage_of_time",
              "name": "percentage_of_time",
              "value": 0
            }
          ]
        }
      ]
    })
    stub = stub_request(:get, "https://www.flippercloud.io/adapter/features?exclude_gate_names=true").
      with({
        headers: {
          'flipper-cloud-token'=>'asdf',
        },
      }).to_return(status: 200, body: body)
    instance = described_class.new(required_options)
    instance.sync

    # Check that remote was fetched.
    expect(stub).to have_been_requested

    # Check that local adapter really did sync.
    local_adapter = instance.local_adapter
    all = local_adapter.get_all
    expect(all.keys).to eq(["search", "history"])
    expect(all["search"][:boolean]).to eq("true")
    expect(all["history"][:boolean]).to eq(nil)
  end

  it "polls in the background and applies changes to local on the calling thread" do
    local_adapter = Flipper::Adapters::OperationLogger.new(Flipper::Adapters::Memory.new)
    Flipper.new(local_adapter).add(:search)

    body = JSON.generate({
      features: [
        {
          key: "search",
          gates: [
            {key: "boolean", value: true},
          ],
        },
      ],
    })
    stub_request(:get, "https://www.flippercloud.io/adapter/features?exclude_gate_names=true").
      to_return(status: 200, body: body)

    configuration = described_class.new(required_options.merge(local_adapter: local_adapter))
    flipper = Flipper::Cloud::DSL.new(configuration)
    local_adapter.reset

    polling_thread = Thread.new { configuration.send(:poller).sync }
    expect(polling_thread.join(1)).to be(polling_thread)

    expect(local_adapter.count).to be(0)

    calling_thread = Thread.current
    mutation_threads = []
    allow(local_adapter).to receive(:enable).and_wrap_original do |original, *args|
      mutation_threads << Thread.current
      original.call(*args)
    end

    expect(flipper.enabled?(:search)).to be(true)
    expect(local_adapter.count(:get_all)).to be(1)
    expect(local_adapter.count(:get)).to be(1)
    expect(local_adapter.count(:enable)).to be(1)
    expect(mutation_threads).to contain_exactly(calling_thread)
  end

  it "reports polling persistence failures while keeping reads available and explicit sync strict" do
    memory = Flipper::Adapters::Memory.new(threadsafe: true)
    persistent = Flipper::Adapters::Memory.new(threadsafe: true)
    local = Flipper::Adapters::DualWrite.new(memory, persistent)
    Flipper.new(local).disable(:search)
    instrumenter = Flipper::Instrumenters::Memory.new
    state = Flipper::Adapters::Sync::IntervalSynchronizer::State.new(synced: true)
    configuration = described_class.new(required_options.merge(
      local_adapter: local,
      synchronization_state: state,
      instrumenter: instrumenter,
    ))
    body = Flipper::Typecast.to_json(features: [{key: "search", gates: [{key: "boolean", value: true}]}])
    stub_request(:get, %r{\Ahttps://www\.flippercloud\.io/adapter/features\?}).
      to_return(status: 200, body: body)
    poller = configuration.send(:poller)
    allow(poller).to receive(:start)
    poller.sync
    failure = StandardError.new("database unavailable")
    allow(persistent).to receive(:enable).and_raise(failure)

    expect(Flipper::Cloud::DSL.new(configuration).enabled?(:search)).to be(false)
    expect(instrumenter.events_by_name("synchronizer_exception.flipper").size).to eq(1)
    expect { configuration.sync(cache_bust: true) }.to raise_error(failure)
    expect(state.last_poll_at).to eq(0)
  end

  it "does not let an older persistence refresh overwrite a forced sync" do
    memory = Flipper::Adapters::Memory.new(threadsafe: true)
    persistent = Flipper::Adapters::Memory.new(threadsafe: true)
    Flipper.new(memory).disable(:search)
    Flipper.new(persistent).disable(:search)
    state = Flipper::Adapters::Sync::IntervalSynchronizer::State.new(synced: true)
    local_adapter = Flipper::Adapters::DualWrite.new(memory, persistent)
    configuration = described_class.new(required_options.merge(
      local_adapter: local_adapter,
      synchronization_state: state,
    ))
    body = Flipper::Typecast.to_json({
      features: [
        {
          key: "search",
          gates: [
            {key: "boolean", value: true},
          ],
        },
      ],
    })
    stub_request(:get, %r{\Ahttps://www\.flippercloud\.io/adapter/features\?}).
      to_return(status: 200, body: body)
    refresh_started = Queue.new
    release_refresh = Queue.new
    refresh = Flipper::Adapters::Sync::IntervalSynchronizer.new(-> {
      old_snapshot = Flipper::Adapters::Memory.new(persistent.get_all)
      refresh_started << true
      release_refresh.pop
      memory.import(old_snapshot)
    }, interval: 10, state: state)
    allow(refresh).to receive(:now).and_return(Process.clock_gettime(Process::CLOCK_MONOTONIC, :second) + 11)

    refresh_thread = Thread.new { refresh.call }
    Timeout.timeout(1) { refresh_started.pop }
    webhook_thread = Thread.new { configuration.sync(cache_bust: true) }
    release_refresh << true
    expect(refresh_thread.join(1)).to be(refresh_thread)
    expect(webhook_thread.join(1)).to be(webhook_thread)

    expect(Flipper.new(memory).enabled?(:search)).to be(true)
    expect(Flipper.new(persistent).enabled?(:search)).to be(true)
  ensure
    release_refresh << true if refresh_thread&.alive?
    refresh_thread&.join(1)
    webhook_thread&.join(1)
  end

  it "does not apply a buffered poll after a forced sync" do
    state = Flipper::Adapters::Sync::IntervalSynchronizer::State.new(synced: true)
    local = Flipper::Adapters::Memory.new(threadsafe: true)
    Flipper.new(local).disable(:search)
    buffered = Flipper::Adapters::Memory.new(threadsafe: true)
    Flipper.new(buffered).disable(:search)
    poller = double(
      "Poller",
      adapter: buffered,
      last_synced_at: Concurrent::AtomicFixnum.new(1),
    )
    allow(poller).to receive(:start)
    state.poll_started
    configuration = described_class.new(required_options.merge(
      local_adapter: local,
      synchronization_state: state,
    ))
    allow(configuration).to receive(:poller).and_return(poller)
    body = Flipper::Typecast.to_json({
      features: [
        {
          key: "search",
          gates: [
            {key: "boolean", value: true},
          ],
        },
      ],
    })
    stub_request(:get, %r{\Ahttps://www\.flippercloud\.io/adapter/features\?}).
      to_return(status: 200, body: body)

    configuration.sync(cache_bust: true)
    flipper = Flipper::Cloud::DSL.new(configuration)

    expect(flipper.enabled?(:search)).to be(true)
    expect(state.last_poll_at).to eq(1)
  end

  it "does not share a poller across synchronization states" do
    uncoordinated = described_class.new(required_options)
    state = Flipper::Adapters::Sync::IntervalSynchronizer::State.new(synced: true)
    coordinated = described_class.new(required_options.merge(synchronization_state: state))

    expect(coordinated.send(:poller)).not_to be(uncoordinated.send(:poller))
  end
end
