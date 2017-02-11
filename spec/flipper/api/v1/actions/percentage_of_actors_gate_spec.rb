require 'helper'

RSpec.describe Flipper::Api::V1::Actions::PercentageOfActorsGate do
  let(:app) { build_api(flipper) }

  describe 'enable' do
    context 'url-encoded request' do
      before do
        flipper[:my_feature].disable
        post '/features/my_feature/percentage_of_actors', percentage: '10'
      end

      it 'enables gate for feature' do
        expect(flipper[:my_feature].enabled_gate_names).to include(:percentage_of_actors)
      end

      it 'returns decorated feature with gate enabled for 10 percent of actors' do
        gate = json_response['gates'].find { |gate| gate['name'] == 'percentage_of_actors' }
        expect(gate['value']).to eq('10')
      end
    end

    context 'json request' do
      before do
        flipper[:my_feature].disable
        post '/features/my_feature/percentage_of_actors',
             { percentage: '10' }.to_json,
             'CONTENT_TYPE' => 'application/json'
      end

      it 'enables gate for feature' do
        expect(flipper[:my_feature].enabled_gate_names).to include(:percentage_of_actors)
      end

      it 'returns decorated feature with gate enabled for 10 percent of actors' do
        gate = json_response['gates'].find { |gate| gate['name'] == 'percentage_of_actors' }
        expect(gate['value']).to eq('10')
      end
    end
  end

  describe 'disable without percentage' do
    before do
      flipper[:my_feature].enable_percentage_of_actors(10)
      delete '/features/my_feature/percentage_of_actors'
    end

    it 'disables gate for feature' do
      expect(flipper[:my_feature].enabled_gates).to be_empty
    end

    it 'returns decorated feature with gate disabled' do
      gate = json_response['gates'].find { |gate| gate['name'] == 'percentage_of_actors' }
      expect(gate['value']).to eq('0')
    end
  end

  describe 'disable with percentage' do
    before do
      flipper[:my_feature].enable_percentage_of_actors(10)
      delete '/features/my_feature/percentage_of_actors',
             { percentage: '5' }.to_json,
             'CONTENT_TYPE' => 'application/json'
    end

    it 'returns decorated feature with gate disabled' do
      gate = json_response['gates'].find { |gate| gate['name'] == 'percentage_of_actors' }
      expect(gate['value']).to eq('5')
    end
  end

  describe 'non-existent feature' do
    before do
      delete '/features/my_feature/percentage_of_actors'
    end

    it 'disables gate for feature' do
      expect(flipper[:my_feature].enabled_gates).to be_empty
    end

    it 'returns decorated feature with gate disabled' do
      expect(last_response.status).to eq(200)
      gate = json_response['gates'].find { |gate| gate['name'] == 'percentage_of_actors' }
      expect(gate['value']).to eq('0')
    end
  end

  describe 'out of range parameter percentage parameter' do
    before do
      flipper[:my_feature].disable
      post '/features/my_feature/percentage_of_actors', percentage: '300'
    end

    it '422s with correct error response when percentage parameter is invalid' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_positive_percentage_error_response)
    end
  end

  describe 'percentage parameter not an integer' do
    before do
      flipper[:my_feature].disable
      post '/features/my_feature/percentage_of_actors', percentage: 'foo'
    end

    it '422s with correct error response when percentage parameter is invalid' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_positive_percentage_error_response)
    end
  end

  describe 'missing percentage parameter' do
    before do
      flipper[:my_feature].disable
      post '/features/my_feature/percentage_of_actors'
    end

    it '422s with correct error response when percentage parameter is missing' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_positive_percentage_error_response)
    end
  end
end
