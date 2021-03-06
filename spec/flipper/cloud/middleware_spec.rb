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
  let(:response_body) { JSON.generate({features: {}}) }
  let(:request_body) {
    JSON.generate({
      "environment_id" => 1,
      "webhook_id" => 1,
      "delivery_id" => SecureRandom.uuid,
      "action" => "sync",
    })
  }
  let(:timestamp) { Time.now }
  let(:signature) {
    Flipper::Cloud::MessageVerifier.new(secret: flipper.sync_secret).generate(request_body, timestamp)
  }
  let(:signature_header_value) {
    Flipper::Cloud::MessageVerifier.new(secret: "").header(signature, timestamp)
  }

  context 'when initializing middleware with flipper instance' do
    let(:app) { Flipper::Cloud.app(flipper) }

    it 'uses instance to sync' do
      Flipper.register(:admins) { |*args| false }
      Flipper.register(:staff) { |*args| false }
      Flipper.register(:basic) { |*args| false }
      Flipper.register(:plus) { |*args| false }
      Flipper.register(:premium) { |*args| false }

      stub = stub_request_for_token('regular')
      env = {
        "HTTP_FLIPPER_CLOUD_SIGNATURE" => signature_header_value,
      }
      post '/', request_body, env

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq({
        "groups" => [
          {"name" => "admins"},
          {"name" => "staff"},
          {"name" => "basic"},
          {"name" => "plus"},
          {"name" => "premium"},
        ],
      })
      expect(stub).to have_been_requested
    end
  end

  context 'when signature is invalid' do
    let(:app) { Flipper::Cloud.app(flipper) }
    let(:signature) {
      Flipper::Cloud::MessageVerifier.new(secret: "nope").generate(request_body, timestamp)
    }

    it 'uses instance to sync' do
      stub = stub_request_for_token('regular')
      env = {
        "HTTP_FLIPPER_CLOUD_SIGNATURE" => signature_header_value,
      }
      post '/', request_body, env

      expect(last_response.status).to eq(400)
      expect(stub).not_to have_been_requested
    end
  end

  context "when flipper cloud responds with 402" do
    let(:app) { Flipper::Cloud.app(flipper) }

    it "results in 402" do
      Flipper.register(:admins) { |*args| false }
      Flipper.register(:staff) { |*args| false }
      Flipper.register(:basic) { |*args| false }
      Flipper.register(:plus) { |*args| false }
      Flipper.register(:premium) { |*args| false }

      stub = stub_request_for_token('regular', status: 402)
      env = {
        "HTTP_FLIPPER_CLOUD_SIGNATURE" => signature_header_value,
      }
      post '/', request_body, env

      expect(last_response.status).to eq(402)
      expect(last_response.headers["Flipper-Cloud-Response-Error-Class"]).to eq("Flipper::Adapters::Http::Error")
      expect(last_response.headers["Flipper-Cloud-Response-Error-Message"]).to eq("Failed with status: 402")
      expect(stub).to have_been_requested
    end
  end

  context "when flipper cloud responds with non-402 and non-2xx code" do
    let(:app) { Flipper::Cloud.app(flipper) }

    it "results in 500" do
      Flipper.register(:admins) { |*args| false }
      Flipper.register(:staff) { |*args| false }
      Flipper.register(:basic) { |*args| false }
      Flipper.register(:plus) { |*args| false }
      Flipper.register(:premium) { |*args| false }

      stub = stub_request_for_token('regular', status: 503)
      env = {
        "HTTP_FLIPPER_CLOUD_SIGNATURE" => signature_header_value,
      }
      post '/', request_body, env

      expect(last_response.status).to eq(500)
      expect(last_response.headers["Flipper-Cloud-Response-Error-Class"]).to eq("Flipper::Adapters::Http::Error")
      expect(last_response.headers["Flipper-Cloud-Response-Error-Message"]).to eq("Failed with status: 503")
      expect(stub).to have_been_requested
    end
  end

  context "when flipper cloud responds with timeout" do
    let(:app) { Flipper::Cloud.app(flipper) }

    it "results in 500" do
      Flipper.register(:admins) { |*args| false }
      Flipper.register(:staff) { |*args| false }
      Flipper.register(:basic) { |*args| false }
      Flipper.register(:plus) { |*args| false }
      Flipper.register(:premium) { |*args| false }

      stub = stub_request_for_token('regular', status: :timeout)
      env = {
        "HTTP_FLIPPER_CLOUD_SIGNATURE" => signature_header_value,
      }
      post '/', request_body, env

      expect(last_response.status).to eq(500)
      expect(last_response.headers["Flipper-Cloud-Response-Error-Class"]).to eq("Net::OpenTimeout")
      expect(last_response.headers["Flipper-Cloud-Response-Error-Message"]).to eq("execution expired")
      expect(stub).to have_been_requested
    end
  end

  context 'when initialized with flipper instance and flipper instance in env' do
    let(:app) { Flipper::Cloud.app(flipper) }
    let(:signature) {
      Flipper::Cloud::MessageVerifier.new(secret: env_flipper.sync_secret).generate(request_body, timestamp)
    }

    it 'uses env instance to sync' do
      stub = stub_request_for_token('env')
      env = {
        "HTTP_FLIPPER_CLOUD_SIGNATURE" => signature_header_value,
        'flipper' => env_flipper,
      }
      post '/', request_body, env

      expect(last_response.status).to eq(200)
      expect(stub).to have_been_requested
    end
  end

  context 'when initialized without flipper instance but flipper instance in env' do
    let(:app) { Flipper::Cloud.app }
    let(:signature) {
      Flipper::Cloud::MessageVerifier.new(secret: env_flipper.sync_secret).generate(request_body, timestamp)
    }

    it 'uses env instance to sync' do
      stub = stub_request_for_token('env')
      env = {
        "HTTP_FLIPPER_CLOUD_SIGNATURE" => signature_header_value,
        'flipper' => env_flipper,
      }
      post '/', request_body, env

      expect(last_response.status).to eq(200)
      expect(stub).to have_been_requested
    end
  end

  context 'when initialized with env_key' do
    let(:app) { Flipper::Cloud.app(flipper, env_key: 'flipper_cloud') }
    let(:signature) {
      Flipper::Cloud::MessageVerifier.new(secret: env_flipper.sync_secret).generate(request_body, timestamp)
    }

    it 'uses provided env key instead of default' do
      stub = stub_request_for_token('env')
      env = {
        "HTTP_FLIPPER_CLOUD_SIGNATURE" => signature_header_value,
        'flipper' => flipper,
        'flipper_cloud' => env_flipper,
      }
      post '/', request_body, env

      expect(last_response.status).to eq(200)
      expect(stub).to have_been_requested
    end
  end

  context 'when initializing lazily with a block' do
    let(:app) { Flipper::Cloud.app(-> { flipper }) }

    it 'works' do
      stub = stub_request_for_token('regular')
      env = {
        "HTTP_FLIPPER_CLOUD_SIGNATURE" => signature_header_value,
      }
      post '/', request_body, env

      expect(last_response.status).to eq(200)
      expect(stub).to have_been_requested
    end
  end

  context 'when using older /webhooks path' do
    let(:app) { Flipper::Cloud.app(flipper) }

    it 'uses instance to sync' do
      Flipper.register(:admins) { |*args| false }
      Flipper.register(:staff) { |*args| false }
      Flipper.register(:basic) { |*args| false }
      Flipper.register(:plus) { |*args| false }
      Flipper.register(:premium) { |*args| false }

      stub = stub_request_for_token('regular')
      env = {
        "HTTP_FLIPPER_CLOUD_SIGNATURE" => signature_header_value,
      }
      post '/webhooks', request_body, env

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq({
        "groups" => [
          {"name" => "admins"},
          {"name" => "staff"},
          {"name" => "basic"},
          {"name" => "plus"},
          {"name" => "premium"},
        ],
      })
      expect(stub).to have_been_requested
    end
  end

  describe 'Request method unsupported' do
    it 'skips middleware' do
      get '/'
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

  def stub_request_for_token(token, status: 200)
    stub = stub_request(:get, "https://www.flippercloud.io/adapter/features").
      with({
        headers: {
          'Flipper-Cloud-Token' => token,
        },
      })
    if status == :timeout
      stub.to_timeout
    else
      stub.to_return(status: status, body: response_body, headers: {})
    end
  end
end
