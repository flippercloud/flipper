require 'helper'

RSpec.describe Flipper::Api do
  describe 'Initializing middleware with flipper instance' do
    let(:app) { build_api(flipper) }

    it 'works' do
      flipper.enable :a
      flipper.disable :b

      get '/features'

      expect(last_response.status).to be(200)
      feature_names = json_response.fetch('features').map { |feature| feature.fetch('key') }
      expect(feature_names).to eq(%w(a b))
    end
  end

  describe 'Initializing middleware lazily with a block' do
    let(:app) { build_api(-> { flipper }) }

    it 'works' do
      flipper.enable :a
      flipper.disable :b

      get '/features'

      expect(last_response.status).to be(200)
      feature_names = json_response.fetch('features').map { |feature| feature.fetch('key') }
      expect(feature_names).to eq(%w(a b))
    end
  end

  context 'when initialized with flipper instance and flipper instance in env' do
    let(:app) { build_api(flipper) }

    it 'uses env instance over initialized instance' do
      flipper[:built_a].enable
      flipper[:built_b].disable

      env_flipper = build_flipper
      env_flipper[:env_a].enable
      env_flipper[:env_b].disable

      params = {}
      env = {
        'flipper' => env_flipper,
      }
      get '/features', params, env

      expect(last_response.status).to eq(200)
      feature_names = json_response.fetch('features').map { |feature| feature.fetch('key') }
      expect(feature_names).to eq(%w(env_a env_b))
    end
  end

  context 'when initialized without flipper instance but flipper instance in env' do
    let(:app) { described_class.app }

    it 'uses env instance' do
      flipper[:a].enable
      flipper[:b].disable

      params = {}
      env = {
        'flipper' => flipper,
      }
      get '/features', params, env

      expect(last_response.status).to eq(200)
      feature_names = json_response.fetch('features').map { |feature| feature.fetch('key') }
      expect(feature_names).to eq(%w(a b))
    end
  end

  context 'when initialized with env_key' do
    let(:app) { build_api(flipper, env_key: 'flipper_api') }

    it 'uses provided env key instead of default' do
      flipper[:a].enable
      flipper[:b].disable

      default_env_flipper = build_flipper
      default_env_flipper[:env_a].enable
      default_env_flipper[:env_b].disable

      params = {}
      env = {
        'flipper' => default_env_flipper,
        'flipper_api' => flipper,
      }
      get '/features', params, env

      expect(last_response.status).to eq(200)
      feature_names = json_response.fetch('features').map { |feature| feature.fetch('key') }
      expect(feature_names).to eq(%w(a b))
    end
  end

  context "when request does not match any api routes" do
    let(:app) { build_api(flipper) }

    it "returns 404" do
      get '/gibberish'
      expect(last_response.status).to eq(404)
      expect(json_response).to eq({})
    end
  end

  describe 'Inspecting the built Rack app' do
    it 'returns a String' do
      expect(build_api(flipper).inspect).to be_a(String)
    end
  end
end
