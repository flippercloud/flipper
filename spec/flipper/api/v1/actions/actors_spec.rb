RSpec.describe Flipper::Api::V1::Actions::Actors do
  let(:app) { build_api(flipper) }
  let(:actor) { Flipper::Actor.new('User123') }

  describe 'GET /actors/:flipper_id' do
    before do
      flipper[:my_feature_1].enable
      flipper[:my_feature_2].disable
      flipper[:my_feature_3].enable_actor(actor)
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
