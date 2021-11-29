RSpec.describe Flipper::Api::V1::Actions::BooleanGate do
  let(:app) { build_api(flipper) }

  describe 'enable' do
    before do
      flipper[:my_feature].disable
      post '/features/my_feature/boolean'
    end

    it 'enables feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].on?).to be_truthy
    end

    it 'returns decorated feature with boolean gate enabled' do
      boolean_gate = json_response['gates'].find { |gate| gate['key'] == 'boolean' }
      expect(boolean_gate['value']).to be_truthy
    end
  end

  describe 'enable feature with slash in name' do
    before do
      flipper["my/feature"].disable
      post '/features/my/feature/boolean'
    end

    it 'enables feature' do
      expect(last_response.status).to eq(200)
      expect(flipper["my/feature"].on?).to be_truthy
    end

    it 'returns decorated feature with boolean gate enabled' do
      boolean_gate = json_response['gates'].find { |gate| gate['key'] == 'boolean' }
      expect(boolean_gate['value']).to be_truthy
    end
  end

  describe 'disable' do
    before do
      flipper[:my_feature].enable
      delete '/features/my_feature/boolean'
    end

    it 'disables feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].off?).to be_truthy
    end

    it 'returns decorated feature with boolean gate disabled' do
      boolean_gate = json_response['gates'].find { |gate| gate['key'] == 'boolean' }
      expect(boolean_gate['value']).to be_falsy
    end
  end
end
