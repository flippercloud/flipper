require 'rails'
require 'flipper/engine'

RSpec.describe Flipper::Engine do
  let(:application) do
    Class.new(Rails::Application) do
      config.eager_load = false
      config.logger = ActiveSupport::Logger.new($stdout)
    end
  end

  before do
    Rails.application = nil
    ActiveSupport::Dependencies.autoload_paths = ActiveSupport::Dependencies.autoload_paths.dup
    ActiveSupport::Dependencies.autoload_once_paths = ActiveSupport::Dependencies.autoload_once_paths.dup
  end

  let(:config) { application.config.flipper }

  subject { application.initialize! }

  context 'cloudless' do
    it 'can set env_key from ENV' do
      ENV['FLIPPER_ENV_KEY'] = 'flopper'

      subject
      expect(config.env_key).to eq('flopper')
    end

    it 'can set memoize from ENV' do
      ENV['FLIPPER_MEMOIZE'] = 'false'

      subject
      expect(config.memoize).to eq(false)
    end

    it 'can set preload from ENV' do
      ENV['FLIPPER_PRELOAD'] = 'false'

      subject
      expect(config.preload).to eq(false)
    end

    it 'can set instrumenter from ENV' do
      stub_const('My::Cool::Instrumenter', Class.new)
      ENV['FLIPPER_INSTRUMENTER'] = 'My::Cool::Instrumenter'

      subject
      expect(config.instrumenter).to eq(My::Cool::Instrumenter)
    end

    it 'can set log from ENV' do
      ENV['FLIPPER_LOG'] = 'false'

      subject
      expect(config.log).to eq(false)
    end

    it 'sets defaults' do
      subject # initialize
      expect(config.env_key).to eq("flipper")
      expect(config.memoize).to be(true)
      expect(config.preload).to be(true)
    end

    it "configures instrumentor on default instance" do
      subject # initialize
      expect(Flipper.instance.instrumenter).to eq(ActiveSupport::Notifications)
    end

    it 'uses Memoizer middleware if config.memoize = true' do
      initializer { config.memoize = true }
      expect(subject.middleware).to include(Flipper::Middleware::Memoizer)
    end

    it 'does not use Memoizer middleware if config.memoize = false' do
      initializer { config.memoize = false }
      expect(subject.middleware).not_to include(Flipper::Middleware::Memoizer)
    end

    it 'passes config to memoizer' do
      initializer do
        config.update(
          env_key: 'my_flipper',
          preload: [:stats, :search]
        )
      end

      expect(subject.middleware).to include(Flipper::Middleware::Memoizer)
      middleware = subject.middleware.detect { |m| m.klass == Flipper::Middleware::Memoizer }
      expect(middleware.args[0]).to eq({
        env_key: config.env_key,
        preload: config.preload,
        if: nil
      })
    end

    it "defines #flipper_id on AR::Base" do
      subject
      require 'active_record'
      expect(ActiveRecord::Base.ancestors).to include(Flipper::Identifier)
    end
  end

  context 'with cloud' do
    let(:env) do
      { "FLIPPER_CLOUD_TOKEN" => "test-token" }
    end

    # App for Rack::Test
    let(:app) { application.routes }

    it "initializes cloud configuration" do
      stub_request(:get, /flippercloud\.io/).to_return(status: 200, body: "{}")

      ENV.update(env)
      application.initialize!

      expect(Flipper.instance).to be_a(Flipper::Cloud::DSL)
      expect(Flipper.instance.instrumenter).to be(ActiveSupport::Notifications)
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
        ENV.update(env)
        application.initialize!

        stub = stub_request(:get, "https://www.flippercloud.io/adapter/features?exclude_gate_names=true").with({
          headers: { "Flipper-Cloud-Token" => ENV["FLIPPER_CLOUD_TOKEN"] },
        }).to_return(status: 200, body: JSON.generate({ features: {} }), headers: {})

        post "/_flipper", request_body, { "HTTP_FLIPPER_CLOUD_SIGNATURE" => signature_header_value }

        expect(last_response.status).to eq(200)
        expect(stub).to have_been_requested
      end
    end

    context "without CLOUD_SYNC_SECRET" do
      it "does not configure webhook app" do
        ENV.update(env)
        application.initialize!

        post "/_flipper"
        expect(last_response.status).to eq(404)
      end
    end

    context "without FLIPPER_CLOUD_TOKEN" do
      it "gracefully skips configuring webhook app" do
        ENV["FLIPPER_CLOUD_TOKEN"] = nil
        application.initialize!
        expect(Flipper.instance).to be_a(Flipper::DSL)

        post "/_flipper"
        expect(last_response.status).to eq(404)
      end
    end
  end

  # Add app initializer in the same order as config/initializers/*
  def initializer(&block)
    application.initializer 'spec', before: :load_config_initializers do
      block.call
    end
  end
end
