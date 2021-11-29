RSpec.describe Flipper::Api::V1::Actions::Features do
  let(:app) { build_api(flipper) }
  let(:feature) { build_feature }
  let(:admin) { double 'Fake Fliper Thing', flipper_id: 10 }

  describe 'get' do
    context 'with flipper features' do
      before do
        flipper[:my_feature].enable
        flipper[:my_feature].enable(admin)
        get '/features'
      end

      it 'responds with correct attributes' do
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
  end

  describe 'post' do
    context 'succesful request' do
      before do
        post '/features', name: 'my_feature'
      end

      it 'responds 200 ' do
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
end
