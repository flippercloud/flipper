require 'helper'

RSpec.describe Flipper::Api::V1::Actions::Actor do
  let(:app) { build_api(flipper) }
  let(:actor) { Flipper::Actor.new('User123') }

  describe 'GET /feature/:feature/actor/:flipper_id' do
    context 'for an enabled feature' do
      before do
        flipper[:my_feature].enable
        get "/feature/my_feature/actor", 'flipper_id' => 'User123'
      end

      it 'responds with success' do
        expect(last_response.status).to eq(200)
      end

      it 'renders template' do
        expected_response = {
          'flipper_id' => 'User123',
          'feature' => 'my_feature',
          'enabled' => true,
        }

        expect(json_response).to eq(expected_response)
      end
    end

    context 'for a feature enabled for that actor' do
      before do
        flipper[:my_feature].enable(actor)
        get "/feature/my_feature/actor", 'flipper_id' => 'User123'
      end

      it 'responds with success' do
        expect(last_response.status).to eq(200)
      end

      it 'renders template' do
        expected_response = {
          'flipper_id' => 'User123',
          'feature' => 'my_feature',
          'enabled' => true,
        }

        expect(json_response).to eq(expected_response)
      end
    end

    context 'for a feature disabled for that actor' do
      before do
        flipper[:my_feature].disable(actor)
        get "/feature/my_feature/actor", 'flipper_id' => 'User123'
      end

      it 'responds with success' do
        expect(last_response.status).to eq(200)
      end

      it 'renders template' do
        expected_response = {
          'flipper_id' => 'User123',
          'feature' => 'my_feature',
          'enabled' => false,
        }

        expect(json_response).to eq(expected_response)
      end
    end

    context 'for a non-existent feature' do
      before do
        get "/feature/not_a_feature/actor", 'flipper_id' => 'User123'
      end

      it 'does not respond with success' do
        expect(last_response.status).to eq(404)
      end

      it 'returns formatted error' do
        expected = {
          'code' => 1,
          'message' => 'Feature not found.',
          'more_info' => api_error_code_reference_url,
        }

        expect(json_response).to eq(expected)
      end
    end

    context 'for a non-existent actor value' do
      before do
        get "/feature/my_feature/actor"
      end

      it 'does not respond with success' do
        expect(last_response.status).to eq(422)
      end

      it 'returns formatted error' do
        expected = {
          'code' => 4,
          'message' => 'Required parameter flipper_id is missing.',
          'more_info' => api_error_code_reference_url,
        }
        expect(json_response).to eq(expected)
      end
    end
  end
end
