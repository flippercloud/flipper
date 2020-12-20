require 'helper'
require 'flipper/cloud/configuration'
require 'flipper/adapters/instrumented'

RSpec.describe Flipper::Cloud::Configuration do
  let(:required_options) do
    { token: "asdf" }
  end

  it "can set token" do
    instance = described_class.new(required_options)
    expect(instance.token).to eq(required_options[:token])
  end

  it "can set token from ENV var" do
    with_modified_env "FLIPPER_CLOUD_TOKEN" => "from_env" do
      instance = described_class.new(required_options.reject { |k, v| k == :token })
      expect(instance.token).to eq("from_env")
    end
  end

  it "can set instrumenter" do
    instrumenter = Object.new
    instance = described_class.new(required_options.merge(instrumenter: instrumenter))
    expect(instance.instrumenter).to be(instrumenter)
  end

  it "can set read_timeout" do
    instance = described_class.new(required_options.merge(read_timeout: 5))
    expect(instance.read_timeout).to eq(5)
  end

  it "can set read_timeout from ENV var" do
    with_modified_env "FLIPPER_CLOUD_READ_TIMEOUT" => "9" do
      instance = described_class.new(required_options.reject { |k, v| k == :read_timeout })
      expect(instance.read_timeout).to eq(9)
    end
  end

  it "can set open_timeout" do
    instance = described_class.new(required_options.merge(open_timeout: 5))
    expect(instance.open_timeout).to eq(5)
  end

  it "can set open_timeout from ENV var" do
    with_modified_env "FLIPPER_CLOUD_OPEN_TIMEOUT" => "9" do
      instance = described_class.new(required_options.reject { |k, v| k == :open_timeout })
      expect(instance.open_timeout).to eq(9)
    end
  end

  it "can set write_timeout" do
    instance = described_class.new(required_options.merge(write_timeout: 5))
    expect(instance.write_timeout).to eq(5)
  end

  it "can set write_timeout from ENV var" do
    with_modified_env "FLIPPER_CLOUD_WRITE_TIMEOUT" => "9" do
      instance = described_class.new(required_options.reject { |k, v| k == :write_timeout })
      expect(instance.write_timeout).to eq(9)
    end
  end

  it "can set sync_interval" do
    instance = described_class.new(required_options.merge(sync_interval: 1))
    expect(instance.sync_interval).to eq(1)
  end

  it "can set sync_interval from ENV var" do
    with_modified_env "FLIPPER_CLOUD_SYNC_INTERVAL" => "5" do
      instance = described_class.new(required_options.reject { |k, v| k == :sync_interval })
      expect(instance.sync_interval).to eq(5)
    end
  end

  it "passes sync_interval into sync adapter" do
    # The initial sync of http to local invokes this web request.
    stub_request(:get, /flippercloud\.io/).to_return(status: 200, body: "{}")

    instance = described_class.new(required_options.merge(sync_interval: 1))
    expect(instance.adapter.synchronizer.interval).to be(1)
  end

  it "can set debug_output" do
    instance = described_class.new(required_options.merge(debug_output: STDOUT))
    expect(instance.debug_output).to eq(STDOUT)
  end

  it "defaults adapter block" do
    # The initial sync of http to local invokes this web request.
    stub_request(:get, /flippercloud\.io/).to_return(status: 200, body: "{}")

    instance = described_class.new(required_options)
    expect(instance.adapter).to be_instance_of(Flipper::Adapters::Sync)
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
    options = required_options.merge(url: "http://localhost:5000/adapter")
    instance = described_class.new(options)
    expect(instance.url).to eq("http://localhost:5000/adapter")

    instance = described_class.new(required_options)
    instance.url = "http://localhost:5000/adapter"
    expect(instance.url).to eq("http://localhost:5000/adapter")
  end

  it "can override URL using ENV var" do
    with_modified_env "FLIPPER_CLOUD_URL" => "https://example.com" do
      instance = described_class.new(required_options.reject { |k, v| k == :url })
      expect(instance.url).to eq("https://example.com")
    end
  end

  it "defaults to sync_method to poll" do
    memory_adapter = Flipper::Adapters::Memory.new
    instance = described_class.new(required_options)

    expect(instance.sync_method).to eq(:poll)
  end

  it "can use webhook for sync_method" do
    memory_adapter = Flipper::Adapters::Memory.new
    instance = described_class.new(required_options.merge({
      sync_secret: "secret",
      sync_method: :webhook,
      local_adapter: memory_adapter,
    }))

    expect(instance.sync_method).to eq(:webhook)
    expect(instance.adapter).to be_instance_of(Flipper::Adapters::DualWrite)
  end

  it "raises ArgumentError for invalid sync_method" do
    expect {
      described_class.new(required_options.merge(sync_method: :foo))
    }.to raise_error(ArgumentError, "Unsupported sync_method. Valid options are (poll, webhook)")
  end

  it "can use ENV var for sync_method" do
    with_modified_env "FLIPPER_CLOUD_SYNC_METHOD" => "webhook" do
      instance = described_class.new(required_options.merge({
        sync_secret: "secret",
      }))

      expect(instance.sync_method).to eq(:webhook)
    end
  end

  it "can use string sync_method instead of symbol" do
    memory_adapter = Flipper::Adapters::Memory.new
    instance = described_class.new(required_options.merge({
      sync_secret: "secret",
      sync_method: "webhook",
      local_adapter: memory_adapter,
    }))

    expect(instance.sync_method).to eq(:webhook)
    expect(instance.adapter).to be_instance_of(Flipper::Adapters::DualWrite)
  end

  it "can set sync_secret" do
    instance = described_class.new(required_options.merge(sync_secret: "from_config"))
      expect(instance.sync_secret).to eq("from_config")
  end

  it "can override sync_secret using ENV var" do
    with_modified_env "FLIPPER_CLOUD_SYNC_SECRET" => "from_env" do
      instance = described_class.new(required_options.reject { |k, v| k == :sync_secret })
      expect(instance.sync_secret).to eq("from_env")
    end
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
    stub = stub_request(:get, "https://www.flippercloud.io/adapter/features").
      with({
        headers: {
          'Flipper-Cloud-Token'=>'asdf',
        },
      }).to_return(status: 200, body: body, headers: {})
    instance = described_class.new(required_options)
    instance.sync

    # Check that remote was fetched.
    expect(stub).to have_been_requested

    # Check that local adapter really did sync.
    local_adapter = instance.adapter.instance_variable_get("@local")
    all = local_adapter.get_all
    expect(all.keys).to eq(["search", "history"])
    expect(all["search"][:boolean]).to eq("true")
    expect(all["history"][:boolean]).to eq(nil)
  end
end
