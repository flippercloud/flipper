RSpec.describe Flipper::Api::V1::Actions::ActorsGate do
  let(:app) { build_api(flipper) }
  let(:actor) { Flipper::Actor.new('1') }

  describe 'enable' do
    before do
      flipper[:my_feature].disable_actor(actor)
      post '/features/my_feature/actors', flipper_id: actor.flipper_id
    end

    it 'enables feature for actor' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].enabled?(actor)).to be_truthy
      expect(flipper[:my_feature].enabled_gate_names).to eq([:actor])
    end

    it 'returns decorated feature with actor enabled' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'actors' }
      expect(gate['value']).to eq(['1'])
    end
  end

  describe 'disable' do
    let(:actor) { Flipper::Actor.new('1') }

    before do
      flipper[:my_feature].enable_actor(actor)
      delete '/features/my_feature/actors', flipper_id: actor.flipper_id
    end

    it 'disables feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].enabled?(actor)).to be_falsy
      expect(flipper[:my_feature].enabled_gate_names).to be_empty
    end

    it 'returns decorated feature with boolean gate disabled' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'actors' }
      expect(gate['value']).to be_empty
    end
  end

  describe 'enable feature with slash in name' do
    before do
      flipper["my/feature"].disable_actor(actor)
      post '/features/my/feature/actors', flipper_id: actor.flipper_id
    end

    it 'enables feature for actor' do
      expect(last_response.status).to eq(200)
      expect(flipper["my/feature"].enabled?(actor)).to be_truthy
      expect(flipper["my/feature"].enabled_gate_names).to eq([:actor])
    end

    it 'returns decorated feature with actor enabled' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'actors' }
      expect(gate['value']).to eq(['1'])
    end
  end

  describe 'enable feature with space in name' do
    before do
      flipper["sp ace"].disable_actor(actor)
      post '/features/sp%20ace/actors', flipper_id: actor.flipper_id
    end

    it 'enables feature for actor' do
      expect(last_response.status).to eq(200)
      expect(flipper["sp ace"].enabled?(actor)).to be_truthy
      expect(flipper["sp ace"].enabled_gate_names).to eq([:actor])
    end

    it 'returns decorated feature with actor enabled' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'actors' }
      expect(gate['value']).to eq(['1'])
    end
  end

  describe 'enable missing flipper_id parameter' do
    before do
      flipper[:my_feature].enable
      post '/features/my_feature/actors'
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_flipper_id_is_missing_response)
    end
  end

  describe 'disable missing flipper_id parameter' do
    before do
      flipper[:my_feature].enable
      delete '/features/my_feature/actors'
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_flipper_id_is_missing_response)
    end
  end

  describe 'enable nil flipper_id parameter' do
    before do
      flipper[:my_feature].enable
      post '/features/my_feature/actors', flipper_id: nil
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_flipper_id_is_missing_response)
    end
  end

  describe 'disable nil flipper_id parameter' do
    before do
      flipper[:my_feature].enable
      delete '/features/my_feature/actors', flipper_id: nil
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_flipper_id_is_missing_response)
    end
  end

  describe 'enable missing feature' do
    before do
      post '/features/my_feature/actors', flipper_id: actor.flipper_id
    end

    it 'enables feature for actor' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].enabled?(actor)).to be_truthy
      expect(flipper[:my_feature].enabled_gate_names).to eq([:actor])
    end

    it 'returns decorated feature with actor enabled' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'actors' }
      expect(gate['value']).to eq(['1'])
    end
  end

  describe 'disable missing feature' do
    before do
      delete '/features/my_feature/actors', flipper_id: actor.flipper_id
    end

    it 'disables feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].enabled?(actor)).to be_falsy
      expect(flipper[:my_feature].enabled_gate_names).to be_empty
    end

    it 'returns decorated feature with boolean gate disabled' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'actors' }
      expect(gate['value']).to be_empty
    end
  end
end
