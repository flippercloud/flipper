require 'securerandom'
require 'helper'
require 'flipper/cloud'
require 'flipper/cloud/middleware'
require 'flipper/adapters/operation_logger'

RSpec.describe Flipper::Cloud::Middleware do
  let(:flipper) {
    Flipper::Cloud.new("regular") do |config|
      config.local_adapter = Flipper::Adapters::OperationLogger.new(Flipper::Adapters::Memory.new)
      config.sync_secret = "regular_tasty"
      config.sync_method = :webhook
    end
  }

  let(:env_flipper) {
    Flipper::Cloud.new("env") do |config|
      config.local_adapter = Flipper::Adapters::OperationLogger.new(Flipper::Adapters::Memory.new)
      config.sync_secret = "env_tasty"
      config.sync_method = :webhook
    end
  }

  let(:app) { Flipper::Cloud.app(flipper) }
  let(:body) { JSON.generate({features: {}}) }
  let(:params) { {} }

  context 'when initializing middleware with flipper instance' do
    let(:app) { Flipper::Cloud.app(flipper) }

    it 'uses instance to sync' do
      stub = stub_request_for_token('regular')
      post '/webhooks', generate_request_body(flipper.sync_secret)

      expect(last_response.status).to eq(200)
      expect(stub).to have_been_requested
    end
  end

  context 'when posted invalid sync secret' do
    let(:app) { Flipper::Cloud.app(flipper) }

    it 'uses instance to sync' do
      stub = stub_request_for_token('regular')
      post '/webhooks', generate_request_body("nope")

      expect(last_response.status).to eq(403)
      expect(stub).not_to have_been_requested
    end
  end

  context 'when initialized with flipper instance and flipper instance in env' do
    let(:app) { Flipper::Cloud.app(flipper) }

    it 'uses env instance to sync' do
      stub = stub_request_for_token('env')
      post '/webhooks', generate_request_body(env_flipper.sync_secret), {'flipper' => env_flipper}

      expect(last_response.status).to eq(200)
      expect(stub).to have_been_requested
    end
  end

  context 'when initialized without flipper instance but flipper instance in env' do
    let(:app) { Flipper::Cloud.app }

    it 'uses env instance to sync' do
      stub = stub_request_for_token('env')
      post '/webhooks', generate_request_body(env_flipper.sync_secret), {'flipper' => env_flipper}

      expect(last_response.status).to eq(200)
      expect(stub).to have_been_requested
    end
  end

  context 'when initialized with env_key' do
    let(:app) { Flipper::Cloud.app(flipper, env_key: 'flipper_cloud') }

    it 'uses provided env key instead of default' do
      stub = stub_request_for_token('env')
      post '/webhooks', generate_request_body(env_flipper.sync_secret), {
        'flipper' => flipper,
        'flipper_cloud' => env_flipper,
      }

      expect(last_response.status).to eq(200)
      expect(stub).to have_been_requested
    end
  end

  context 'when initializing lazily with a block' do
    let(:app) { Flipper::Cloud.app(-> { flipper }) }

    it 'works' do
      stub = stub_request_for_token('regular')
      post '/webhooks', generate_request_body(flipper.sync_secret)

      expect(last_response.status).to eq(200)
      expect(stub).to have_been_requested
    end
  end

  describe 'Request method unsupported' do
    it 'skips middleware' do
      get '/webhooks'
      expect(last_response.status).to eq(404)
      expect(last_response.content_type).to eq("application/json")
      expect(last_response.body).to eq("{}")
    end
  end

  describe 'Inspecting the built Rack app' do
    it 'returns a String' do
      expect(Flipper::Cloud.app(flipper).inspect).to be_a(String)
    end
  end

  private

  def generate_request_body(sync_secret)
    JSON.generate({
      "environment_id" => 1,
      "webhook_id" => 1,
      "webhook_secret" => sync_secret,
      "delivery_id" => SecureRandom.uuid,
      "action" => "sync",
    })
  end

  def stub_request_for_token(token)
    stub_request(:get, "https://www.flippercloud.io/adapter/features").
      with({
        headers: {
          'Flipper-Cloud-Token' => token,
        },
      }).to_return(status: 200, body: body, headers: {})
  end
end
