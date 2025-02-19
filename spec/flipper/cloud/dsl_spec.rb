require 'flipper/cloud/configuration'
require 'flipper/cloud/dsl'
require 'flipper/adapters/operation_logger'
require 'flipper/adapters/instrumented'

RSpec.describe Flipper::Cloud::DSL do
  it 'delegates everything to flipper instance' do
    cloud_configuration = Flipper::Cloud::Configuration.new({
      token: "asdf",
      sync_secret: "tasty",
    })
    dsl = described_class.new(cloud_configuration)
    expect(dsl.features).to eq(Set.new)
    expect(dsl.enabled?(:foo)).to be(false)
  end

  it 'delegates sync to cloud configuration' do
    stub = stub_request(:get, "https://www.flippercloud.io/adapter/features?exclude_gate_names=true").
      with({
        headers: {
          'flipper-cloud-token'=>'asdf',
        },
      }).to_return(status: 200, body: '{"features": {}}', headers: {})
    cloud_configuration = Flipper::Cloud::Configuration.new({
      token: "asdf",
      sync_secret: "tasty",
    })
    dsl = described_class.new(cloud_configuration)
    dsl.sync
    expect(stub).to have_been_requested
  end

  it 'delegates sync_secret to cloud configuration' do
    cloud_configuration = Flipper::Cloud::Configuration.new({
      token: "asdf",
      sync_secret: "tasty",
    })
    dsl = described_class.new(cloud_configuration)
    expect(dsl.sync_secret).to eq("tasty")
  end

  context "when sync_method is webhook" do
    let(:local_adapter) do
      Flipper::Adapters::OperationLogger.new Flipper::Adapters::Memory.new
    end

    let(:cloud_configuration) do
      Flipper::Cloud::Configuration.new({
        token: "asdf",
        sync_secret: "tasty",
        local_adapter: local_adapter
      })
    end

    subject do
      described_class.new(cloud_configuration)
    end

    it "sends reads to local adapter" do
      subject.features
      subject.enabled?(:foo)
      expect(local_adapter.count(:features)).to be(1)
      expect(local_adapter.count(:get)).to be(1)
    end

    it "sends writes to cloud and local" do
      add_stub = stub_request(:post, "https://www.flippercloud.io/adapter/features").
        with({headers: {'flipper-cloud-token'=>'asdf'}}).
        to_return(status: 200, body: '{}')
      enable_stub = stub_request(:post, "https://www.flippercloud.io/adapter/features/foo/boolean").
        with(headers: {'flipper-cloud-token'=>'asdf'}).
        to_return(status: 200, body: '{}')

      subject.enable(:foo)

      expect(local_adapter.count(:add)).to be(1)
      expect(local_adapter.count(:enable)).to be(1)
      expect(add_stub).to have_been_requested
      expect(enable_stub).to have_been_requested
    end
  end
end
