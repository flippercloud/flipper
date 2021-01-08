require 'helper'
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
      @instance = described_class.new(token)
      memoized_adapter = @instance.adapter
      sync_adapter = memoized_adapter.adapter
      @http_adapter = sync_adapter.instance_variable_get('@remote')
      @http_client = @http_adapter.instance_variable_get('@client')
    end

    it 'returns Flipper::DSL instance' do
      expect(@instance).to be_instance_of(Flipper::Cloud::DSL)
    end

    it 'can read the cloud configuration' do
      expect(@instance.cloud_configuration).to be_instance_of(Flipper::Cloud::Configuration)
    end

    it 'configures instance to use http adapter' do
      expect(@http_adapter).to be_instance_of(Flipper::Adapters::Http)
    end

    it 'sets up correct url' do
      uri = @http_client.instance_variable_get('@uri')
      expect(uri.scheme).to eq('https')
      expect(uri.host).to eq('www.flippercloud.io')
      expect(uri.path).to eq('/adapter')
    end

    it 'sets correct token header' do
      headers = @http_client.instance_variable_get('@headers')
      expect(headers['Flipper-Cloud-Token']).to eq(token)
    end

    it 'uses noop instrumenter' do
      expect(@instance.instrumenter).to be(Flipper::Instrumenters::Noop)
    end
  end

  context 'initialize with token and options' do
    before do
      stub_request(:get, /fakeflipper\.com/).to_return(status: 200, body: "{}")

      @instance = described_class.new('asdf', url: 'https://www.fakeflipper.com/sadpanda')
      memoized_adapter = @instance.adapter
      sync_adapter = memoized_adapter.adapter
      @http_adapter = sync_adapter.instance_variable_get('@remote')
      @http_client = @http_adapter.instance_variable_get('@client')
    end

    it 'sets correct url' do
      uri = @http_client.instance_variable_get('@uri')
      expect(uri.scheme).to eq('https')
      expect(uri.host).to eq('www.fakeflipper.com')
      expect(uri.path).to eq('/sadpanda')
    end
  end

  it 'can initialize with no token explicitly provided' do
    with_modified_env "FLIPPER_CLOUD_TOKEN" => "asdf" do
      expect(described_class.new).to be_instance_of(Flipper::Cloud::DSL)
    end
  end

  it 'can set instrumenter' do
    instrumenter = Flipper::Instrumenters::Memory.new
    instance = described_class.new('asdf', instrumenter: instrumenter)
    expect(instance.instrumenter).to be(instrumenter)
  end

  it 'allows wrapping adapter with another adapter like the instrumenter' do
    instance = described_class.new('asdf') do |config|
      config.adapter do |adapter|
        Flipper::Adapters::Instrumented.new(adapter)
      end
    end
    # instance.adapter is memoizable adapter instance
    expect(instance.adapter.adapter).to be_instance_of(Flipper::Adapters::Instrumented)
  end

  it 'can set debug_output' do
    expect(Flipper::Adapters::Http::Client).to receive(:new)
      .with(hash_including(debug_output: STDOUT))
    described_class.new('asdf', debug_output: STDOUT)
  end

  it 'can set read_timeout' do
    expect(Flipper::Adapters::Http::Client).to receive(:new)
      .with(hash_including(read_timeout: 1))
    described_class.new('asdf', read_timeout: 1)
  end

  it 'can set open_timeout' do
    expect(Flipper::Adapters::Http::Client).to receive(:new)
      .with(hash_including(open_timeout: 1))
    described_class.new('asdf', open_timeout: 1)
  end

  if RUBY_VERSION >= '2.6.0'
    it 'can set write_timeout' do
      expect(Flipper::Adapters::Http::Client).to receive(:new)
        .with(hash_including(open_timeout: 1))
      described_class.new('asdf', open_timeout: 1)
    end
  end

  it 'can import' do
    stub_request(:post, /www\.flippercloud\.io\/adapter\/features.*/).
      with(headers: {
          'Feature-Flipper-Token'=>'asdf',
          'Flipper-Cloud-Token'=>'asdf',
      }).to_return(status: 200, body: "{}", headers: {})

    flipper = Flipper.new(Flipper::Adapters::Memory.new)

    flipper.enable(:test)
    flipper.enable(:search)
    flipper.enable_actor(:stats, Flipper::Actor.new("jnunemaker"))
    flipper.enable_percentage_of_time(:logging, 5)

    cloud_flipper = Flipper::Cloud.new("asdf")

    get_all = {
      "logging" => {actors: Set.new, boolean: nil, groups: Set.new, percentage_of_actors: nil, percentage_of_time: "5"},
      "search" => {actors: Set.new, boolean: "true", groups: Set.new, percentage_of_actors: nil, percentage_of_time: nil},
      "stats" => {actors: Set["jnunemaker"], boolean: nil, groups: Set.new, percentage_of_actors: nil, percentage_of_time: nil},
      "test" => {actors: Set.new, boolean: "true", groups: Set.new, percentage_of_actors: nil, percentage_of_time: nil},
    }

    expect(flipper.adapter.get_all).to eq(get_all)
    cloud_flipper.import(flipper)
    expect(flipper.adapter.get_all).to eq(get_all)
    expect(cloud_flipper.adapter.get_all).to eq(get_all)
  end

  it 'raises error for timeout while importing' do
    stub_request(:post, /www\.flippercloud\.io\/adapter\/features.*/).
      with(headers: {
          'Feature-Flipper-Token'=>'asdf',
          'Flipper-Cloud-Token'=>'asdf',
      }).to_timeout

    flipper = Flipper.new(Flipper::Adapters::Memory.new)

    flipper.enable(:test)
    flipper.enable(:search)
    flipper.enable_actor(:stats, Flipper::Actor.new("jnunemaker"))
    flipper.enable_percentage_of_time(:logging, 5)

    cloud_flipper = Flipper::Cloud.new("asdf")

    get_all = {
      "logging" => {actors: Set.new, boolean: nil, groups: Set.new, percentage_of_actors: nil, percentage_of_time: "5"},
      "search" => {actors: Set.new, boolean: "true", groups: Set.new, percentage_of_actors: nil, percentage_of_time: nil},
      "stats" => {actors: Set["jnunemaker"], boolean: nil, groups: Set.new, percentage_of_actors: nil, percentage_of_time: nil},
      "test" => {actors: Set.new, boolean: "true", groups: Set.new, percentage_of_actors: nil, percentage_of_time: nil},
    }

    expect(flipper.adapter.get_all).to eq(get_all)
    expect { cloud_flipper.import(flipper) }.to raise_error(Net::OpenTimeout)
    expect(flipper.adapter.get_all).to eq(get_all)
  end
end
