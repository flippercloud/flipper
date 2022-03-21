RSpec.describe Flipper::Api::V1::Actions::Feature do
  let(:app) { build_api(flipper) }
  let(:feature) { build_feature }
  let(:gate) { feature.gate(:boolean) }

  describe 'get' do
    context 'enabled feature' do
      before do
        flipper[:my_feature].enable
        get '/features/my_feature'
      end

      it 'responds with correct attributes' do
        response_body = {
          'key' => 'my_feature',
          'state' => 'on',
          'gates' => [
            {
              'key' => 'boolean',
              'name' => 'boolean',
              'value' => 'true',
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

        expect(last_response.status).to eq(200)
        expect(json_response).to eq(response_body)
      end
    end

    context 'disabled feature' do
      before do
        flipper[:my_feature].disable
        get '/features/my_feature'
      end

      it 'responds with correct attributes' do
        response_body = {
          'key' => 'my_feature',
          'state' => 'off',
          'gates' => [
            {
              'key' => 'boolean',
              'name' => 'boolean',
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

        expect(last_response.status).to eq(200)
        expect(json_response).to eq(response_body)
      end
    end

    context 'feature does not exist' do
      before do
        get '/features/not_a_feature'
      end

      it '404s' do
        expect(last_response.status).to eq(404)
        expected = {
          'code' => 1,
          'message' => 'Feature not found.',
          'more_info' => api_error_code_reference_url,
        }
        expect(json_response).to eq(expected)
      end
    end

    context 'feature with name that ends in "features"' do
      before do
        flipper[:search_features].enable
        get '/features/search_features'
      end

      it 'responds with correct attributes' do
        response_body = {
          'key' => 'search_features',
          'state' => 'on',
          'gates' => [
            {
              'key' => 'boolean',
              'name' => 'boolean',
              'value' => 'true',
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

        expect(last_response.status).to eq(200)
        expect(json_response).to eq(response_body)
      end
    end

    context 'feature with name that has slash' do
      before do
        flipper["my/feature"].enable
        get '/features/my/feature'
      end

      it 'responds with correct attributes' do
        response_body = {
          'key' => 'my/feature',
          'state' => 'on',
          'gates' => [
            {
              'key' => 'boolean',
              'name' => 'boolean',
              'value' => 'true',
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

        expect(last_response.status).to eq(200)
        expect(json_response).to eq(response_body)
      end
    end
  end

  describe 'delete' do
    context 'succesful request' do
      it 'deletes feature' do
        flipper[:my_feature].enable
        expect(flipper.features.map(&:key)).to include('my_feature')
        delete '/features/my_feature'
        expect(last_response.status).to eq(204)
        expect(flipper.features.map(&:key)).not_to include('my_feature')
      end
    end

    context 'feature not found' do
      before do
        delete '/features/my_feature'
      end

      it 'responds with 204' do
        expect(last_response.status).to eq(204)
        expect(flipper.features.map(&:key)).not_to include('my_feature')
      end
    end
  end
end
