RSpec.describe Flipper::Api::V1::Actions::Features do
  let(:app) { build_api(flipper) }
  let(:feature) { build_feature }
  let(:admin) { double 'Fake Fliper Thing', flipper_id: 10 }

  describe 'get' do
    malformed_queries = {
      'array-shaped exclude_gate_names' => 'exclude_gate_names[]=true',
      'hash-shaped exclude_gates' => 'exclude_gates[a]=true',
      'hash-shaped keys' => 'keys[a]=my_feature',
      'nested array-shaped keys' => 'keys[][]=my_feature',
      'a bare percent escape' => 'keys=%',
      'a truncated percent escape' => 'keys=%2',
      'an invalid percent escape in a value' => 'keys=%GG',
      'an invalid percent escape in a key' => '%GG=value',
      'invalid UTF-8 in a key' => '%FF=value&keys=my_feature',
      'invalid UTF-8' => 'keys=%FF',
      'conflicting parameter shapes' => 'a=1&a[]=2',
      'excessive nesting' => "a#{'[a]' * 150}=1",
      'excessive parameter count' => (1..5000).map { |index| "ignored#{index}=1" }.join('&'),
    }

    malformed_queries.each do |description, query|
      it "fails open for #{description}" do
        flipper[:my_feature].enable
        expected_response = raw_api_get('/features', '')

        response = raw_api_get('/features', query)

        expect(response.first).to eq(200)
        expect(response).to eq(expected_response)
      end
    end

    it 'fully fails open when malformed syntax is combined with a valid option' do
      flipper[:my_feature].enable
      expected_response = raw_api_get('/features', '')

      response = raw_api_get('/features', 'a=1&a[]=2&exclude_gate_names=true')

      expect(response.first).to eq(200)
      expect(response).to eq(expected_response)
    end

    separator_queries = [
      '&exclude_gate_names=true',
      '&&exclude_gate_names=true&&',
      ';exclude_gate_names=true',
      ';;exclude_gate_names=true;;',
      'exclude_gate_names=true&&;;',
    ]

    separator_queries.each do |query|
      it "preserves optional parameter semantics with empty query segments in #{query.inspect}" do
        flipper[:my_feature].enable
        expected_response = raw_api_get('/features', 'exclude_gate_names=true')

        response = raw_api_get('/features', query)

        expect(response.first).to eq(200)
        expect(response).to eq(expected_response)
      end
    end

    it 'fails open when decoding a raw query component raises ArgumentError' do
      request = instance_double(Rack::Request, query_string: 'keys=%')
      action = described_class.new(flipper, request)
      allow(action).to receive(:safe_params).and_return('keys' => 'my_feature')
      allow(Rack::Utils).to receive(:unescape).with('keys').and_return('keys')
      allow(Rack::Utils).to receive(:unescape).with('%').and_raise(ArgumentError)

      expect(action.send(:requested_feature_names)).to be_nil
    end

    it 'uses parsed keys when no raw keys parameter is present' do
      request = instance_double(Rack::Request, query_string: 'other=value')
      action = described_class.new(flipper, request)
      allow(action).to receive(:safe_params).and_return('keys' => 'my_feature,other_feature')

      expect(action.send(:requested_feature_names)).to eq(%w[my_feature other_feature])
    end

    {
      'keys=my_feature&keys=other_feature' => %w[my_feature other_feature],
      'keys=&keys=my_feature' => %w[my_feature],
      '=&keys=my_feature&=value' => %w[my_feature],
      'keys' => [],
      'keys[]' => [],
      'keys=' => [],
    }.each do |query, expected_keys|
      it "preserves duplicate and blank parameter semantics for #{query.inspect}" do
        flipper[:my_feature].enable
        flipper[:other_feature].disable

        status, _, body = raw_api_get('/features', query)
        keys = body.fetch('features').map { |feature| feature.fetch('key') }.sort

        expect(status).to eq(200)
        expect(keys).to eq(expected_keys.sort)
      end
    end

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

      it 'responds without gates when instructed by param' do
        get '/features', 'exclude_gates' => 'true'

        expect(last_response.status).to eq(200)
        expect(json_response).to eq(
          'features' => [
            {
              'key' => 'my_feature',
              'state' => 'on',
            },
          ]
        )
      end

      it 'ignores a leading empty query segment' do
        get '/features?exclude_gate_names=true'
        expected_response = json_response

        get '/features?&exclude_gate_names=true'

        expect(last_response.status).to eq(200)
        expect(json_response).to eq(expected_response)
      end

      it 'ignores consecutive and trailing empty query segments' do
        get '/features?exclude_gate_names=true'
        expected_response = json_response

        get '/features?&&exclude_gate_names=true&&;'

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

    context 'with keys containing commas' do
      before do
        flipper["audit,log"].enable
        flipper[:search].enable
        get '/features?keys[]=audit%2Clog&keys[]=search'
      end

      it 'treats escaped commas as part of the feature key' do
        expect(last_response.status).to eq(200)
        keys = json_response.fetch('features').map { |feature| feature.fetch('key') }.sort
        expect(keys).to eq(["audit,log", "search"])
      end
    end

    context 'with a single encoded key containing a comma' do
      before do
        flipper["audit,log"].enable
        get '/features?keys=audit%2Clog'
      end

      it 'treats the escaped comma as part of the feature key' do
        expect(last_response.status).to eq(200)
        keys = json_response.fetch('features').map { |feature| feature.fetch('key') }
        expect(keys).to eq(["audit,log"])
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

    context 'with many requested keys' do
      require 'flipper/adapters/operation_logger'

      let(:adapter) { Flipper::Adapters::OperationLogger.new(build_memory_adapter) }
      let(:flipper) { build_flipper(adapter) }

      before do
        flipper[:search].enable
        flipper[:stats].enable
        adapter.reset
      end

      it 'enumerates the feature set once regardless of how many keys are requested' do
        get "/features?keys=#{(1..50).map { |i| "key_#{i}" }.join(',')}"

        expect(last_response.status).to eq(200)
        expect(adapter.count(:features)).to eq(1)
      end

      it 'enumerates the feature set once for repeated keys params' do
        get "/features?#{(1..50).map { |i| "keys=key_#{i}" }.join('&')}"

        expect(last_response.status).to eq(200)
        expect(adapter.count(:features)).to eq(1)
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

    context 'feature name contains invisible characters' do
      before do
        post '/features', name: "my_\u3164\u115Ffeature\u1160\uFFA0\u2800\u17B4"
      end

      it 'responds 200' do
        expect(last_response.status).to eq(200)
      end

      it 'adds feature with invisible characters removed' do
        expect(flipper.features.map(&:key)).to eq(['my_feature'])
      end
    end

    context 'feature name normalizes to empty' do
      before do
        post '/features', name: "\u3164\u115F\u1160\uFFA0\u2800\u17B4"
      end

      it 'returns correct status code' do
        expect(last_response.status).to eq(422)
      end

      it 'does not add feature' do
        expect(flipper.features).to be_empty
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
end
