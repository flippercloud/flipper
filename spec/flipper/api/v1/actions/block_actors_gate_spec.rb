RSpec.describe Flipper::Api::V1::Actions::BlockActorsGate do
  let(:app) { build_api(flipper) }
  let(:actor) { Flipper::Actor.new('1') }

  describe 'block' do
    before do
      post '/features/my_feature/block_actors', flipper_id: actor.flipper_id
    end

    it 'blocks actor for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].block_actors_value).to include('1')
    end

    it 'returns decorated feature with block_actors gate' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'block_actors' }
      expect(gate['value']).to eq(['1'])
    end
  end

  describe 'unblock' do
    before do
      flipper[:my_feature].block_actor(actor)
      delete '/features/my_feature/block_actors', flipper_id: actor.flipper_id
    end

    it 'unblocks actor for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].block_actors_value).to be_empty
    end

    it 'returns decorated feature with empty block_actors gate' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'block_actors' }
      expect(gate['value']).to be_empty
    end
  end

  describe 'block with slash in feature name' do
    before do
      post '/features/my/feature/block_actors', flipper_id: actor.flipper_id
    end

    it 'blocks actor for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper["my/feature"].block_actors_value).to include('1')
    end

    it 'returns decorated feature with block_actors gate' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'block_actors' }
      expect(gate['value']).to eq(['1'])
    end
  end

  describe 'block with space in feature name' do
    before do
      post '/features/sp%20ace/block_actors', flipper_id: actor.flipper_id
    end

    it 'blocks actor for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper["sp ace"].block_actors_value).to include('1')
    end

    it 'returns decorated feature with block_actors gate' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'block_actors' }
      expect(gate['value']).to eq(['1'])
    end
  end

  describe 'block missing flipper_id parameter' do
    before do
      post '/features/my_feature/block_actors'
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_flipper_id_is_missing_response)
    end
  end

  describe 'unblock missing flipper_id parameter' do
    before do
      delete '/features/my_feature/block_actors'
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_flipper_id_is_missing_response)
    end
  end

  describe 'block nil flipper_id parameter' do
    before do
      post '/features/my_feature/block_actors', flipper_id: nil
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_flipper_id_is_missing_response)
    end
  end

  describe 'unblock nil flipper_id parameter' do
    before do
      delete '/features/my_feature/block_actors', flipper_id: nil
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_flipper_id_is_missing_response)
    end
  end
end
