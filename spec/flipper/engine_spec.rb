require 'rails'
require 'flipper/engine'

RSpec.describe Flipper::Engine do
  let(:application) do
    Class.new(Rails::Application) do
      config.load_defaults Rails::VERSION::STRING.to_f
      config.eager_load = false
      config.logger = ActiveSupport::Logger.new($stdout)
      config.active_support.remove_deprecated_time_with_zone_name = false
    end.instance
  end

  before do
    stub_request(:get, /flippercloud\.io/).to_return(status: 200, body: "{}")
    Rails.application = nil
    ActiveSupport::Dependencies.autoload_paths = ActiveSupport::Dependencies.autoload_paths.dup
    ActiveSupport::Dependencies.autoload_once_paths = ActiveSupport::Dependencies.autoload_once_paths.dup
  end

  # Reset Rails.env around each example
  around do |example|
    begin
      env = Rails.env.to_s
      example.run
    ensure
      Rails.env = env
    end
  end

  let(:config) { application.config.flipper }

  subject { SpecHelpers.silence { application.initialize! } }

  shared_examples 'config.strict' do
    let(:adapter) { Flipper.adapter.adapter }

    it 'can set strict=true from ENV' do
      ENV['FLIPPER_STRICT'] = 'true'
      subject
      expect(config.strict).to eq(:raise)
      expect(adapter).to be_instance_of(Flipper::Adapters::Strict)
    end

    it 'can set strict=warn from ENV' do
      ENV['FLIPPER_STRICT'] = 'warn'
      subject
      expect(config.strict).to eq(:warn)
      expect(adapter).to be_instance_of(Flipper::Adapters::Strict)
      expect(adapter.handler).to be(:warn)
    end

    it 'can set strict=false from ENV' do
      ENV['FLIPPER_STRICT'] = 'false'
      subject
      expect(config.strict).to eq(false)
      expect(adapter).not_to be_instance_of(Flipper::Adapters::Strict)
    end

    [true, :raise, :warn].each do |value|
      it "can set strict=#{value.inspect} in initializer" do
        initializer { config.strict = value }
        subject
        expect(adapter).to be_instance_of(Flipper::Adapters::Strict)
        expect(adapter.handler).to be(value)
      end
    end

    it "can set strict=false in initializer" do
      initializer { config.strict = false }
      subject
      expect(config.strict).to eq(false)
      expect(adapter).not_to be_instance_of(Flipper::Adapters::Strict)
    end

    it "defaults to strict=:warn in RAILS_ENV=development" do
      Rails.env = "development"
      subject
      expect(config.strict).to eq(:warn)
      expect(adapter).to be_instance_of(Flipper::Adapters::Strict)
    end

    %w(production test).each do |env|
      it "defaults to strict=warn in RAILS_ENV=#{env}" do
        Rails.env = env
        expect(Rails.env).to eq(env)
        subject
        expect(config.strict).to eq(false)
        expect(adapter).not_to be_instance_of(Flipper::Adapters::Strict)
      end
    end

    it "defaults to strict=warn in RAILS_ENV=development" do
      Rails.env = "development"
      expect(Rails.env).to eq("development")
      subject
      expect(config.strict).to eq(:warn)
      expect(adapter).to be_instance_of(Flipper::Adapters::Strict)
      expect(adapter.handler).to be(:warn)
    end
  end

  context 'cloudless' do
    it_behaves_like 'config.strict'

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

    context "test_help" do
      it "is loaded if RAILS_ENV=test" do
        Rails.env = "test"
        allow(Flipper::Engine.instance).to receive(:require).and_call_original
        expect(Flipper::Engine.instance).to receive(:require).with("flipper/test_help")
        subject
        expect(config.test_help).to eq(true)
      end

      it "is loaded if FLIPPER_TEST_HELP=true" do
        ENV["FLIPPER_TEST_HELP"] = "true"
        allow(Flipper::Engine.instance).to receive(:require).and_call_original
        expect(Flipper::Engine.instance).to receive(:require).with("flipper/test_help")
        subject
        expect(config.test_help).to eq(true)
      end

      it "is loaded if config.flipper.test_help = true" do
        initializer { config.test_help = true }
        allow(Flipper::Engine.instance).to receive(:require).and_call_original
        expect(Flipper::Engine.instance).to receive(:require).with("flipper/test_help")
        subject
      end

      it "is not loaded if FLIPPER_TEST_HELP=false" do
        ENV["FLIPPER_TEST_HELP"] = "false"
        allow(Flipper::Engine.instance).to receive(:require).and_call_original
        expect(Flipper::Engine.instance).to receive(:require).with("flipper/test_help").never
        subject
      end

      it "is not loaded if config.flipper.test_help = false" do
        Rails.env = "true"
        initializer { config.test_help = false }
        allow(Flipper::Engine.instance).to receive(:require).and_call_original
        expect(Flipper::Engine.instance).to receive(:require).with("flipper/test_help").never
        subject
      end
    end
  end

  context 'with cloud' do
    before do
      ENV["FLIPPER_CLOUD_TOKEN"] = "test-token"
    end

    # App for Rack::Test
    let(:app) { application.routes }

    it_behaves_like 'config.strict' do
      let(:adapter) do
        memoizable = Flipper.adapter
        dual_write = memoizable.adapter
        poll = dual_write.local
        poll.adapter
      end
    end

    it "initializes cloud configuration" do
      stub_request(:get, /flippercloud\.io/).to_return(status: 200, body: "{}")

      silence { application.initialize! }

      expect(Flipper.instance).to be_a(Flipper::Cloud::DSL)
      expect(Flipper.instance.instrumenter).to be_a(Flipper::Cloud::Telemetry::Instrumenter)
      expect(Flipper.instance.instrumenter.instrumenter).to be(ActiveSupport::Notifications)
    end

    context "with CLOUD_SYNC_SECRET" do
      before do
        ENV["FLIPPER_CLOUD_SYNC_SECRET"] = "test-secret"
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
        Flipper::Cloud::MessageVerifier.new(secret: ENV["FLIPPER_CLOUD_SYNC_SECRET"]).generate(request_body, timestamp)
      }
      let(:signature_header_value) {
        Flipper::Cloud::MessageVerifier.new(secret: "").header(signature, timestamp)
      }

      it "configures webhook app" do
        silence { application.initialize! }

        stub = stub_request(:get, "https://www.flippercloud.io/adapter/features?exclude_gate_names=true").with({
          headers: { "flipper-cloud-token" => ENV["FLIPPER_CLOUD_TOKEN"] },
        }).to_return(status: 200, body: JSON.generate({ features: {} }), headers: {})

        post "/_flipper", request_body, { "HTTP_FLIPPER_CLOUD_SIGNATURE" => signature_header_value }

        expect(last_response.status).to eq(200)
        expect(stub).to have_been_requested
      end
    end

    context "without CLOUD_SYNC_SECRET" do
      it "does not configure webhook app" do
        silence { application.initialize! }

        post "/_flipper"
        expect(last_response.status).to eq(404)
      end
    end

    context "without FLIPPER_CLOUD_TOKEN" do
      it "gracefully skips configuring webhook app" do
        ENV["FLIPPER_CLOUD_TOKEN"] = nil
        silence { application.initialize! }
        expect(Flipper.instance).to be_a(Flipper::DSL)

        post "/_flipper"
        expect(last_response.status).to eq(404)
      end
    end
  end

  context 'with cloud secrets in Rails.credentials' do
    around do |example|
      # Create temporary directory for Rails.root to write credentials to
      # Once Rails 5.2 support is dropped, this can all be replaced with
      # `config.credentials.content_path = Tempfile.new.path`
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          Dir.mkdir("#{dir}/config")

          example.run
        end
      end
    end

    before do
      # Set master key which is needed to write credentials
      ENV["RAILS_MASTER_KEY"] = "a" * 32

      application.credentials.write(YAML.dump({
        flipper: {
          cloud_token: "credentials-token",
          cloud_sync_secret: "credentials-secret",
        }
      }))
    end

    it "enables cloud" do
      silence { application.initialize! }
      expect(ENV["FLIPPER_CLOUD_TOKEN"]).to eq("credentials-token")
      expect(ENV["FLIPPER_CLOUD_SYNC_SECRET"]).to eq("credentials-secret")
      expect(Flipper.instance).to be_a(Flipper::Cloud::DSL)
    end
  end

  it "includes model methods" do
    subject
    require 'active_record'
    expect(ActiveRecord::Base.ancestors).to include(Flipper::Model::ActiveRecord)
  end

  describe "config.actor_limit" do
    let(:adapter) do
      silence { application.initialize! }
      Flipper.adapter.adapter.adapter
    end

    it "defaults to 100" do
      expect(adapter).to be_instance_of(Flipper::Adapters::ActorLimit)
      expect(adapter.limit).to eq(100)
    end

    it "can be set from FLIPPER_ACTOR_LIMIT env" do
      ENV["FLIPPER_ACTOR_LIMIT"] = "500"
      expect(adapter.limit).to eq(500)
    end

    it "can be set from an initializer" do
      initializer { config.actor_limit = 99 }
      expect(adapter.limit).to eq(99)
    end

    it "can be disabled from an initializer" do
      initializer { config.actor_limit = false }
      expect(adapter).not_to be_instance_of(Flipper::Adapters::ActorLimit)
    end
  end

  # Add app initializer in the same order as config/initializers/*
  def initializer(&block)
    application.initializer 'spec', before: :load_config_initializers do
      block.call
    end
  end
end
