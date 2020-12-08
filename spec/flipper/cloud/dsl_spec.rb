require 'helper'
require 'flipper/cloud/configuration'
require 'flipper/cloud/dsl'
require 'flipper/adapters/instrumented'

RSpec.describe Flipper::Cloud::DSL do
  it 'delegates everything to flipper instance' do
    cloud_configuration = Flipper::Cloud::Configuration.new({
      token: "asdf",
      sync_method: :webhook,
    })
    dsl = described_class.new(cloud_configuration)
    expect(dsl.features).to eq(Set.new)
    expect(dsl.enabled?(:foo)).to be(false)
  end

  it 'delegates sync to cloud configuration' do
    stub = stub_request(:get, "https://www.flippercloud.io/adapter/features").
      with({
        headers: {
          'Flipper-Cloud-Token'=>'asdf',
        },
      }).to_return(status: 200, body: '{"features": {}}', headers: {})
    cloud_configuration = Flipper::Cloud::Configuration.new({
      token: "asdf",
      sync_method: :webhook,
    })
    dsl = described_class.new(cloud_configuration)
    dsl.sync
    expect(stub).to have_been_requested
  end
end
