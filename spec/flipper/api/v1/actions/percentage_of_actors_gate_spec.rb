require 'helper'

RSpec.describe Flipper::Api::V1::Actions::PercentageOfActorsGate do
  let(:app) { build_api(flipper) }

  describe 'enable' do
    before do
      flipper[:my_feature].disable
      post '/api/v1/features/my_feature/percentage_of_actors', { percentage: '10' }
    end

    it 'enables gate for feature' do
      expect(flipper[:my_feature].enabled_gate_names).to include(:percentage_of_actors)
    end

    it 'returns decorated feature with gate enabled for 10 percent of actors' do
      gate = json_response['gates'].find { |gate| gate['name'] == 'percentage_of_actors' }
      expect(gate['value']).to eq(10)
    end

  end

  describe 'disable' do
    before do
      flipper[:my_feature].disable
      delete '/api/v1/features/my_feature/percentage_of_actors'
    end

    it 'disables gate for feature' do
      expect(flipper[:my_feature].enabled_gates).to be_empty
    end

    it 'returns decorated feature with gate disabled' do
      gate = json_response['gates'].find { |gate| gate['name'] == 'percentage_of_actors' }
      expect(gate['value']).to eq(0)
    end
  end

  describe 'non-existent feature' do
    before do
      delete '/api/v1/features/my_feature/percentage_of_actors'
    end

    it  '404s with correct error response when feature does not exist' do
      expect(last_response.status).to eq(404)
      expect(json_response).to eq({ 'code' => 1, 'message' => 'Feature not found.', 'more_info' => '' })
    end
  end

  describe 'out of range parameter percentage parameter' do
    before do
      flipper[:my_feature].disable
      post '/api/v1/features/my_feature/percentage_of_actors', { percentage: '300' }
    end

    it '400s with correct error response when percentage parameter is invalid' do
      expect(last_response.status).to eq(400)
      expect(json_response).to eq({ 'code' => 3, 'message' => 'Percentage must be a positive number less than or equal to 100.', 'more_info' => '' })
    end
  end

  describe 'percentage parameter not an integer' do
    before do
      flipper[:my_feature].disable
      post '/api/v1/features/my_feature/percentage_of_actors', { percentage: 'foo' }
    end

    it '400s with correct error response when percentage parameter is invalid' do
      expect(last_response.status).to eq(400)
      expect(json_response).to eq({ 'code' => 3, 'message' => 'Percentage must be a positive number less than or equal to 100.', 'more_info' => '' })
    end
  end

  describe 'missing percentage parameter' do
    before do
      flipper[:my_feature].disable
      post '/api/v1/features/my_feature/percentage_of_actors'
    end

    it '400s with correct error response when percentage parameter is missing' do
      expect(last_response.status).to eq(400)
      expect(json_response).to eq({ 'code' => 3, 'message' => 'Percentage must be a positive number less than or equal to 100.', 'more_info' => '' })
    end
  end
end
