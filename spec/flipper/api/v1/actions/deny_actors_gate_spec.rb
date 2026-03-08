RSpec.describe Flipper::Api::V1::Actions::DenyActorsGate do
  let(:app) { build_api(flipper) }
  let(:actor) { Flipper::Actor.new('1') }

  describe 'deny' do
    before do
      post '/features/my_feature/deny_actors', flipper_id: actor.flipper_id
    end

    it 'denies actor for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].deny_actors_value).to include('1')
    end

    it 'returns decorated feature with deny_actors gate' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'deny_actors' }
      expect(gate['value']).to eq(['1'])
    end
  end

  describe 'permit' do
    before do
      flipper[:my_feature].deny_actor(actor)
      delete '/features/my_feature/deny_actors', flipper_id: actor.flipper_id
    end

    it 'undenies actor for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].deny_actors_value).to be_empty
    end

    it 'returns decorated feature with empty deny_actors gate' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'deny_actors' }
      expect(gate['value']).to be_empty
    end
  end

  describe 'deny with slash in feature name' do
    before do
      post '/features/my/feature/deny_actors', flipper_id: actor.flipper_id
    end

    it 'denies actor for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper["my/feature"].deny_actors_value).to include('1')
    end

    it 'returns decorated feature with deny_actors gate' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'deny_actors' }
      expect(gate['value']).to eq(['1'])
    end
  end

  describe 'deny with space in feature name' do
    before do
      post '/features/sp%20ace/deny_actors', flipper_id: actor.flipper_id
    end

    it 'denies actor for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper["sp ace"].deny_actors_value).to include('1')
    end

    it 'returns decorated feature with deny_actors gate' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'deny_actors' }
      expect(gate['value']).to eq(['1'])
    end
  end

  describe 'deny missing flipper_id parameter' do
    before do
      post '/features/my_feature/deny_actors'
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_flipper_id_is_missing_response)
    end
  end

  describe 'permit missing flipper_id parameter' do
    before do
      delete '/features/my_feature/deny_actors'
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_flipper_id_is_missing_response)
    end
  end

  describe 'deny nil flipper_id parameter' do
    before do
      post '/features/my_feature/deny_actors', flipper_id: nil
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_flipper_id_is_missing_response)
    end
  end

  describe 'permit nil flipper_id parameter' do
    before do
      delete '/features/my_feature/deny_actors', flipper_id: nil
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_flipper_id_is_missing_response)
    end
  end
end
