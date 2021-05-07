require 'helper'
require 'rails'
require 'flipper/cloud'

RSpec.describe Flipper::Cloud::Engine do
  let(:env) do
    { "FLIPPER_CLOUD_TOKEN" => "test-token" }
  end

  let(:application) do
    Class.new(Rails::Application) do
      config.eager_load = false
      config.logger = ActiveSupport::Logger.new($stdout)
    end
  end

  # App for Rack::Test
  let(:app) { application.routes }

  before do
    Rails.application = nil

    # Force loading of flipper to configure itself
    load 'flipper/cloud.rb'
  end

  it "initializes cloud configuration" do
    stub_request(:get, /flippercloud\.io/).to_return(status: 200, body: "{}")

    with_modified_env env do
      application.initialize!

      expect(Flipper.instance).to be_a(Flipper::Cloud::DSL)
      expect(Flipper.instance.instrumenter).to be(ActiveSupport::Notifications)
    end
  end

  context "with CLOUD_SYNC_SECRET" do
    before do
      env.update "FLIPPER_CLOUD_SYNC_SECRET" => "test-secret"
    end

    let(:request_body) do
      JSON.generate({
        "environment_id" => 1,
        "webhook_id" => 1,
        "delivery_id" => SecureRandom.uuid,
        "action" => "sync",
      })
    end
    let(:timestamp) { Time.now }
    let(:signature) {
      Flipper::Cloud::MessageVerifier.new(secret: env["FLIPPER_CLOUD_SYNC_SECRET"]).generate(request_body, timestamp)
    }
    let(:signature_header_value) {
      Flipper::Cloud::MessageVerifier.new(secret: "").header(signature, timestamp)
    }

    it "configures webhook app" do
      with_modified_env env do
        application.initialize!

        stub = stub_request(:get, "https://www.flippercloud.io/adapter/features").with({
          headers: { "Flipper-Cloud-Token" => ENV["FLIPPER_CLOUD_TOKEN"] },
        }).to_return(status: 200, body: JSON.generate({ features: {} }), headers: {})

        post "/_flipper", request_body, { "HTTP_FLIPPER_CLOUD_SIGNATURE" => signature_header_value }

        expect(last_response.status).to eq(200)
        expect(stub).to have_been_requested
      end
    end
  end

  context "without CLOUD_SYNC_SECRET" do
    it "does not configure webhook app" do
      with_modified_env env do
        application.initialize!

        post "/_flipper"
        expect(last_response.status).to eq(404)
      end
    end
  end

  context "without FLIPPER_CLOUD_TOKEN" do
    it "gracefully skips configuring webhook app" do
      with_modified_env "FLIPPER_CLOUD_TOKEN" => nil do
        application.initialize!
        expect(silence { Flipper.instance }).to match(/Missing FLIPPER_CLOUD_TOKEN/)
        expect(Flipper.instance).to be_a(Flipper::DSL)

        post "/_flipper"
        expect(last_response.status).to eq(404)
      end
    end
  end
end
