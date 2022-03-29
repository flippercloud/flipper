RSpec.describe Flipper::Api::V1::Actions::DeniedActorsGate do
  let(:app) { build_api(flipper) }
  let(:actor) { Flipper::Actor.new('1') }

  describe 'deny' do
    before do
      flipper[:my_feature].enable_actor(actor)
      flipper[:my_feature].reinstate_actor(actor)
      post '/features/my_feature/denied_actors', flipper_id: actor.flipper_id
    end

    it 'denies feature for actor' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].enabled?(actor)).to be_falsy
    end
  end

  describe 'reinstate' do
    let(:actor) { Flipper::Actor.new('1') }

    before do
      flipper[:my_feature].enable_actor(actor)
      flipper[:my_feature].deny_actor(actor)
      delete '/features/my_feature/denied_actors', flipper_id: actor.flipper_id
    end

    it 'reinstates feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].enabled?(actor)).to be_truthy
      expect(flipper[:my_feature].enabled_gate_names).not_to be_empty
    end
  end

  describe 'deny feature with slash in name' do
    before do
      flipper["my/feature"].enable_actor(actor)
      flipper["my/feature"].reinstate_actor(actor)
      post '/features/my/feature/denied_actors', flipper_id: actor.flipper_id
    end

    it 'denies feature for actor' do
      expect(last_response.status).to eq(200)
      expect(flipper["my/feature"].enabled?(actor)).to be_falsy
    end
  end

  describe 'deny feature with space in name' do
    before do
      flipper["sp ace"].enable_actor(actor)
      flipper["sp ace"].reinstate_actor(actor)
      post '/features/sp%20ace/denied_actors', flipper_id: actor.flipper_id
    end

    it 'denies feature for actor' do
      expect(last_response.status).to eq(200)
      expect(flipper["sp ace"].enabled?(actor)).to be_falsy
    end
  end
  

  describe 'deny missing flipper_id parameter' do
    before do
      post '/features/my_feature/denied_actors'
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_flipper_id_is_missing_response)
    end
  end

  describe 'reinstate missing flipper_id parameter' do
    before do
      delete '/features/my_feature/denied_actors'
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_flipper_id_is_missing_response)
    end
  end

  describe 'deny nil flipper_id parameter' do
    before do
      post '/features/my_feature/denied_actors', flipper_id: nil
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_flipper_id_is_missing_response)
    end
  end

  describe 'reinstate nil flipper_id parameter' do
    before do
      delete '/features/my_feature/denied_actors', flipper_id: nil
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_flipper_id_is_missing_response)
    end
  end
end
