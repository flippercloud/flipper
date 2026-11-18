RSpec.describe Flipper::Api::V1::Actions::Actors do
  let(:app) { build_api(flipper) }
  let(:actor) { Flipper::Actor.new('User123') }

  describe 'GET /actors/:flipper_id' do
    before do
      flipper[:my_feature_1].enable
      flipper[:my_feature_2].disable
      flipper[:my_feature_3].enable_actor(actor)
    end

    malformed_queries = {
      'array-shaped keys' => 'keys[]=my_feature_1',
      'hash-shaped keys' => 'keys[a]=my_feature_1',
      'a bare percent escape' => 'keys=%',
      'an invalid percent escape' => 'keys=%GG',
      'invalid UTF-8' => 'keys=%FF',
      'conflicting parameter shapes' => 'a=1&a[]=2',
      'excessive nesting' => "a#{'[a]' * 150}=1",
    }

    malformed_queries.each do |description, query|
      it "ignores #{description}" do
        expected_response = raw_api_get("/actors/#{actor.flipper_id}", '')

        response = raw_api_get("/actors/#{actor.flipper_id}", query)

        expect(response.first).to eq(200)
        expect(response).to eq(expected_response)
      end
    end

    context 'when no feature is specified' do
      before do
        get "/actors/#{actor.flipper_id}"
      end

      it 'responds with success' do
        expect(last_response.status).to eq(200)
      end

      it 'returns all features' do
        expected_response = {
          'flipper_id' => 'User123',
          'features' => {
            'my_feature_1' => {
              'enabled' => true,
            },
            'my_feature_2' => {
              'enabled' => false,
            },
            'my_feature_3' => {
              'enabled' => true,
            },
          },
        }

        expect(json_response).to eq(expected_response)
      end
    end

    context 'when features are specified' do
      before do
        get "/actors/#{actor.flipper_id}", keys: "my_feature_2,my_feature_3"
      end

      it 'responds with success' do
        expect(last_response.status).to eq(200)
      end

      it 'returns all specified features' do
        expected_response = {
          'flipper_id' => 'User123',
          'features' => {
            'my_feature_2' => {
              'enabled' => false,
            },
            'my_feature_3' => {
              'enabled' => true,
            },
          },
        }

        expect(json_response).to eq(expected_response)
      end
    end

    context 'when non-existent features are specified' do
      before do
        get "/actors/#{actor.flipper_id}", keys: "my_feature_3,not_a_feature"
      end

      it 'responds with success' do
        expect(last_response.status).to eq(200)
      end

      it 'returns false for a non-existent feature' do
        expected_response = {
          'flipper_id' => 'User123',
          'features' => {
            'my_feature_3' => {
              'enabled' => true,
            },
            'not_a_feature' => {
              'enabled' => false,
            },
          },
        }

        expect(json_response).to eq(expected_response)
      end
    end

    # PATH_INFO as a server hands it over: raw bytes, still percent-encoded.
    # Separate from raw_api_get so this file doesn't touch the shared helper
    # that #1107 also changes.
    def get_actor_path(path, query_string)
      env = Rack::MockRequest.env_for('/actors/placeholder', 'QUERY_STRING' => query_string)
      env['PATH_INFO'] = path.b
      status, _headers, body = app.call(env)
      [status, JSON.parse(body.each_with_object(+'') { |part, buffer| buffer << part })]
    ensure
      body.close if body.respond_to?(:close)
    end

    {
      '/actors/User;1' => 'User;1',
      '/actors/User%3B1' => 'User;1',
      '/actors/John%20Doe' => 'John Doe',
      '/actors/user+tag@example.com' => 'user+tag@example.com',
      '/actors/user%2Btag%40example.com' => 'user+tag@example.com',
      '/actors/caf%C3%A9' => 'café',
      '/actors/café' => 'café',
      '/actors/50%off' => '50%off',
    }.each do |path, flipper_id|
      it "reads #{path} as flipper id #{flipper_id.inspect}" do
        flipper[:my_feature_4].enable_actor(Flipper::Actor.new(flipper_id))

        status, body = get_actor_path(path, 'keys=my_feature_4')

        expect(status).to eq(200)
        expect(body['flipper_id']).to eq(flipper_id)
        expect(body['features']['my_feature_4']['enabled']).to be(true)
      end
    end

    it 'rejects a flipper id that is not valid UTF-8' do
      status, body = get_actor_path('/actors/%FF', '')

      expect(status).to eq(400)
      expect(body['code']).to eq(8)
    end

    context 'when flipper id is missing' do
      before do
        get "/actors"
      end

      it 'responds with a 404' do
        expect(last_response.status).to eq(404)
      end
    end
  end
end
