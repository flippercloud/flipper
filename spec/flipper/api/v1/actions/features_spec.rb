RSpec.describe Flipper::Api::V1::Actions::Features do
  let(:app) { build_api(flipper) }
  let(:feature) { build_feature }
  let(:admin) { double 'Fake Fliper Thing', flipper_id: 10 }

  describe 'get' do
    context 'with flipper features' do
      before do
        flipper[:my_feature].enable
        flipper[:my_feature].enable(admin)
      end

      it 'responds with correct attributes' do
        get '/features'

        expected_response = {
          'features' => [
            {
              'key' => 'my_feature',
              'state' => 'on',
              'gates' => [
                {
                  'key' => 'boolean',
                  'name' => 'boolean',
                  'value' => 'true',
                },
                {
                  'key' => 'expression',
                  'name' => 'expression',
                  'value' => nil,
                },
                {
                  'key' => 'actors',
                  'name' => 'actor',
                  'value' => ['10'],
                },
                {
                  'key' => 'percentage_of_actors',
                  'name' => 'percentage_of_actors',
                  'value' => nil,
                },
                {
                  'key' => 'percentage_of_time',
                  'name' => 'percentage_of_time',
                  'value' => nil,
                },
                {
                  'key' => 'groups',
                  'name' => 'group',
                  'value' => [],
                },
              ],
            },
          ],
        }
        expect(last_response.status).to eq(200)
        expect(json_response).to eq(expected_response)
      end

      it 'responds without names when instructed by param' do
        expected_response = {
          'features' => [
            {
              'key' => 'my_feature',
              'state' => 'on',
              'gates' => [
                { 'key' => 'boolean', 'value' => 'true'},
                {"key" => "expression", "value" => nil},
                { 'key' => 'actors', 'value' => ['10']},
                {'key' => 'percentage_of_actors', 'value' => nil},
                { 'key' => 'percentage_of_time', 'value' => nil},
                { 'key' => 'groups', 'value' => []},
              ],
            },
          ],
        }

        get '/features', 'exclude_gate_names' => 'true'
        expect(last_response.status).to eq(200)
        expect(json_response).to eq(expected_response)
      end
    end

    context 'with keys specified' do
      before do
        flipper[:audit_log].enable
        flipper[:issues].enable
        flipper[:search].enable
        flipper[:stats].disable
        get '/features', 'keys' => 'search,stats'
      end

      it 'responds with correct attributes' do
        expect(last_response.status).to eq(200)
        keys = json_response.fetch('features').map { |feature| feature.fetch('key') }.sort
        expect(keys).to eq(%w(search stats))
      end
    end

    context 'with keys that are not existing features' do
      before do
        flipper[:search].disable
        flipper[:stats].disable
        get '/features', 'keys' => 'search,stats,not_a_feature,another_feature_that_does_not_exist'
      end

      it 'only returns features that exist' do
        expect(last_response.status).to eq(200)
        keys = json_response.fetch('features').map { |feature| feature.fetch('key') }.sort
        expect(keys).to eq(%w(search stats))
      end
    end

    context 'with no flipper features' do
      before do
        get '/features'
      end

      it 'returns empty array for features key' do
        expected_response = {
          'features' => [],
        }
        expect(last_response.status).to eq(200)
        expect(json_response).to eq(expected_response)
      end
    end

    context 'with accept encoding header set to gzip' do
      before do
        flipper[:my_feature].enable
        flipper[:my_feature].enable(admin)
      end

      it 'responds with content encoding gzip and correct attributes' do
        get '/features', {}, 'HTTP_ACCEPT_ENCODING' => 'gzip'

        expected_response = {
          'features' => [
            {
              'key' => 'my_feature',
              'state' => 'on',
              'gates' => [
                {
                  'key' => 'boolean',
                  'name' => 'boolean',
                  'value' => 'true',
                },
                {
                  'key' => 'expression',
                  'name' => 'expression',
                  'value' => nil,
                },
                {
                  'key' => 'actors',
                  'name' => 'actor',
                  'value' => ['10'],
                },
                {
                  'key' => 'percentage_of_actors',
                  'name' => 'percentage_of_actors',
                  'value' => nil,
                },
                {
                  'key' => 'percentage_of_time',
                  'name' => 'percentage_of_time',
                  'value' => nil,
                },
                {
                  'key' => 'groups',
                  'name' => 'group',
                  'value' => [],
                },
              ],
            },
          ],
        }
        expect(last_response["content-encoding"]).to eq('gzip')
        expect(last_response.status).to eq(200)
        expect(json_response).to eq(expected_response)
      end
    end
  end

  describe 'post' do
    context 'succesful request' do
      before do
        post '/features', name: 'my_feature'
      end

      it 'responds 200' do
        expect(last_response.status).to eq(200)
      end

      it 'returns decorated feature' do
        expected_response = {
          'key' => 'my_feature',
          'state' => 'off',
          'gates' => [
            {
              'key' => 'boolean',
              'name' => 'boolean',
              'value' => nil,
            },
            {
              'key' => 'expression',
              'name' => 'expression',
              'value' => nil,
            },
            {
              'key' => 'actors',
              'name' => 'actor',
              'value' => [],
            },
            {
              'key' => 'percentage_of_actors',
              'name' => 'percentage_of_actors',
              'value' => nil,
            },
            {
              'key' => 'percentage_of_time',
              'name' => 'percentage_of_time',
              'value' => nil,
            },
            {
              'key' => 'groups',
              'name' => 'group',
              'value' => [],
            },
          ],
        }
        expect(json_response).to eq(expected_response)
      end

      it 'adds feature' do
        expect(flipper.features.map(&:key)).to include('my_feature')
      end

      it 'does not enable feature' do
        expect(flipper['my_feature'].enabled?).to be_falsy
      end
    end

    context 'bad request' do
      before do
        post '/features'
      end

      it 'returns correct status code' do
        expect(last_response.status).to eq(422)
      end

      it 'returns formatted error' do
        expected = {
          'code' => 5,
          'message' => 'Required parameter name is missing.',
          'more_info' => api_error_code_reference_url,
        }
        expect(json_response).to eq(expected)
      end
    end
  end

  describe 'response_extensions' do
    around do |example|
      original = described_class.response_extensions.dup
      described_class.response_extensions.clear
      example.run
      described_class.response_extensions.replace(original)
    end

    it 'merges hashes returned by registered procs into the response' do
      described_class.response_extensions << ->(action) { { version: 12345 } }

      get '/features'

      expect(last_response.status).to eq(200)
      expect(json_response.fetch('version')).to eq(12345)
      expect(json_response).to have_key('features')
    end

    it 'composes multiple extensions in registration order' do
      described_class.response_extensions << ->(action) { { a: 1, b: 1 } }
      described_class.response_extensions << ->(action) { { b: 2, c: 3 } }

      get '/features'

      expect(json_response.fetch('a')).to eq(1)
      expect(json_response.fetch('b')).to eq(2)
      expect(json_response.fetch('c')).to eq(3)
    end

    it 'passes the action instance so extensions can read request, params, and flipper' do
      captured = nil
      described_class.response_extensions << ->(action) {
        captured = action
        {}
      }

      get '/features'

      expect(captured).to be_a(described_class)
      expect(captured.request).to respond_to(:params)
      expect(captured.flipper).to respond_to(:features)
    end

    it 'is a no-op when no extensions are registered' do
      get '/features'

      expect(last_response.status).to eq(200)
      expect(json_response.keys).to eq(['features'])
    end

    it 'does not let extensions overwrite the built-in features key' do
      flipper[:my_feature].enable
      described_class.response_extensions << ->(action) { { features: 'clobbered' } }

      get '/features'

      expect(last_response.status).to eq(200)
      features = json_response.fetch('features')
      expect(features).to be_an(Array)
      expect(features.first.fetch('key')).to eq('my_feature')
    end

    it 'is initialized eagerly at class load time' do
      expect(described_class.instance_variable_defined?(:@response_extensions)).to be(true)
    end
  end
end
