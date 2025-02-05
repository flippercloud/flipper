require 'flipper/cloud'
require 'flipper/adapters/instrumented'
require 'flipper/instrumenters/memory'

RSpec.describe Flipper::Cloud do
  before do
    stub_request(:get, /flippercloud\.io/).to_return(status: 200, body: "{}")
  end

  context "initialize with token" do
    let(:token) { 'asdf' }

    before do
      @instance = described_class.new(token: token)
    end

    it 'returns Flipper::DSL instance' do
      expect(@instance).to be_instance_of(Flipper::Cloud::DSL)
    end

    it 'can read the cloud configuration' do
      expect(@instance.cloud_configuration).to be_instance_of(Flipper::Cloud::Configuration)
    end

    it 'configures the correct adapter' do
      # pardon the nesting...
      memoized_adapter = @instance.adapter
      dual_write_adapter = memoized_adapter.adapter
      expect(dual_write_adapter).to be_instance_of(Flipper::Adapters::DualWrite)
      poll_adapter = dual_write_adapter.local
      expect(poll_adapter).to be_instance_of(Flipper::Adapters::Poll)

      http_adapter = dual_write_adapter.remote
      client = http_adapter.client
      expect(client.uri.scheme).to eq('https')
      expect(client.uri.host).to eq('www.flippercloud.io')
      expect(client.uri.path).to eq('/adapter')
      expect(client.headers["flipper-cloud-token"]).to eq(token)
      expect(@instance.instrumenter).to be_a(Flipper::Cloud::Telemetry::Instrumenter)
      expect(@instance.instrumenter.instrumenter).to be(Flipper::Instrumenters::Noop)
    end
  end

  context 'initialize with token and options' do
    it 'sets correct url' do
      stub_request(:any, %r{fakeflipper.com}).to_return(status: 200)
      instance = described_class.new(token: 'asdf', url: 'https://www.fakeflipper.com/sadpanda')
      # pardon the nesting...
      memoized = instance.adapter
      dual_write = memoized.adapter
      remote = dual_write.remote
      uri = remote.client.uri
      expect(uri.scheme).to eq('https')
      expect(uri.host).to eq('www.fakeflipper.com')
      expect(uri.path).to eq('/sadpanda')
    end
  end

  it 'can initialize with no token explicitly provided' do
    ENV['FLIPPER_CLOUD_TOKEN'] = 'asdf'
    expect(described_class.new).to be_instance_of(Flipper::Cloud::DSL)
  end

  it 'can set instrumenter' do
    instrumenter = Flipper::Instrumenters::Memory.new
    instance = described_class.new(token: 'asdf', instrumenter: instrumenter)
    expect(instance.instrumenter).to be_a(Flipper::Cloud::Telemetry::Instrumenter)
    expect(instance.instrumenter.instrumenter).to be(instrumenter)
  end

  it 'allows wrapping adapter with another adapter like the instrumenter' do
    instance = described_class.new(token: 'asdf') do |config|
      config.adapter do |adapter|
        Flipper::Adapters::Instrumented.new(adapter)
      end
    end
    # instance.adapter is memoizable adapter instance
    expect(instance.adapter.adapter).to be_instance_of(Flipper::Adapters::Instrumented)
  end

  it 'can set debug_output' do
    instance = Flipper::Adapters::Http::Client.new(token: 'asdf', url: 'https://www.flippercloud.io/adapter')
    expect(Flipper::Adapters::Http::Client).to receive(:new)
      .with(hash_including(debug_output: STDOUT)).at_least(:once).and_return(instance)
    described_class.new(token: 'asdf', debug_output: STDOUT)
  end

  it 'can set read_timeout' do
    instance = Flipper::Adapters::Http::Client.new(token: 'asdf', url: 'https://www.flippercloud.io/adapter')
    expect(Flipper::Adapters::Http::Client).to receive(:new)
      .with(hash_including(read_timeout: 1)).at_least(:once).and_return(instance)
    described_class.new(token: 'asdf', read_timeout: 1)
  end

  it 'can set open_timeout' do
    instance = Flipper::Adapters::Http::Client.new(token: 'asdf', url: 'https://www.flippercloud.io/adapter')
    expect(Flipper::Adapters::Http::Client).to receive(:new)
      .with(hash_including(open_timeout: 1)).at_least(:once).and_return(instance)
    described_class.new(token: 'asdf', open_timeout: 1)
  end

  if RUBY_VERSION >= '2.6.0'
    it 'can set write_timeout' do
      instance = Flipper::Adapters::Http::Client.new(token: 'asdf', url: 'https://www.flippercloud.io/adapter')
      expect(Flipper::Adapters::Http::Client).to receive(:new)
        .with(hash_including(open_timeout: 1)).at_least(:once).and_return(instance)
      described_class.new(token: 'asdf', open_timeout: 1)
    end
  end

  it 'can import' do
    stub_request(:post, /www\.flippercloud\.io\/adapter\/features.*/).
      with(headers: {'flipper-cloud-token'=>'asdf'}).to_return(status: 200, body: "{}", headers: {})

    flipper = Flipper.new(Flipper::Adapters::Memory.new)

    flipper.enable(:test)
    flipper.enable(:search)
    flipper.enable_actor(:stats, Flipper::Actor.new("jnunemaker"))
    flipper.enable_percentage_of_time(:logging, 5)

    cloud_flipper = Flipper::Cloud.new(token: "asdf")

    get_all = {
      "logging" => {actors: Set.new, boolean: nil, groups: Set.new, expression: nil, percentage_of_actors: nil, percentage_of_time: "5"},
      "search" => {actors: Set.new, boolean: "true", groups: Set.new, expression: nil, percentage_of_actors: nil, percentage_of_time: nil},
      "stats" => {actors: Set["jnunemaker"], boolean: nil, groups: Set.new, expression: nil, percentage_of_actors: nil, percentage_of_time: nil},
      "test" => {actors: Set.new, boolean: "true", groups: Set.new, expression: nil, percentage_of_actors: nil, percentage_of_time: nil},
    }

    expect(flipper.adapter.get_all).to eq(get_all)
    cloud_flipper.import(flipper)
    expect(flipper.adapter.get_all).to eq(get_all)
    expect(cloud_flipper.adapter.get_all).to eq(get_all)
  end

  it 'raises error for failure while importing' do
    stub_request(:post, /www\.flippercloud\.io\/adapter\/features.*/).
      with(headers: {'flipper-cloud-token'=>'asdf'}).to_return(status: 500, body: "{}")

    flipper = Flipper.new(Flipper::Adapters::Memory.new)

    flipper.enable(:test)
    flipper.enable(:search)
    flipper.enable_actor(:stats, Flipper::Actor.new("jnunemaker"))
    flipper.enable_percentage_of_time(:logging, 5)

    cloud_flipper = Flipper::Cloud.new(token: "asdf")

    get_all = {
      "logging" => {actors: Set.new, boolean: nil, groups: Set.new, expression: nil, percentage_of_actors: nil, percentage_of_time: "5"},
      "search" => {actors: Set.new, boolean: "true", groups: Set.new, expression: nil, percentage_of_actors: nil, percentage_of_time: nil},
      "stats" => {actors: Set["jnunemaker"], boolean: nil, groups: Set.new, expression: nil, percentage_of_actors: nil, percentage_of_time: nil},
      "test" => {actors: Set.new, boolean: "true", groups: Set.new, expression: nil, percentage_of_actors: nil, percentage_of_time: nil},
    }

    expect(flipper.adapter.get_all).to eq(get_all)
    expect { cloud_flipper.import(flipper) }.to raise_error(Flipper::Adapters::Http::Error)
    expect(flipper.adapter.get_all).to eq(get_all)
  end

  it 'raises error for timeout while importing' do
    stub_request(:post, /www\.flippercloud\.io\/adapter\/features.*/).
      with(headers: {'flipper-cloud-token'=>'asdf'}).to_timeout

    flipper = Flipper.new(Flipper::Adapters::Memory.new)

    flipper.enable(:test)
    flipper.enable(:search)
    flipper.enable_actor(:stats, Flipper::Actor.new("jnunemaker"))
    flipper.enable_percentage_of_time(:logging, 5)

    cloud_flipper = Flipper::Cloud.new(token: "asdf")

    get_all = {
      "logging" => {actors: Set.new, boolean: nil, groups: Set.new, expression: nil, percentage_of_actors: nil, percentage_of_time: "5"},
      "search" => {actors: Set.new, boolean: "true", groups: Set.new, expression: nil, percentage_of_actors: nil, percentage_of_time: nil},
      "stats" => {actors: Set["jnunemaker"], boolean: nil, groups: Set.new, expression: nil, percentage_of_actors: nil, percentage_of_time: nil},
      "test" => {actors: Set.new, boolean: "true", groups: Set.new, expression: nil, percentage_of_actors: nil, percentage_of_time: nil},
    }

    expect(flipper.adapter.get_all).to eq(get_all)
    expect { cloud_flipper.import(flipper) }.to raise_error(Net::OpenTimeout)
    expect(flipper.adapter.get_all).to eq(get_all)
  end
end
