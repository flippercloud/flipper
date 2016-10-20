require 'helper'

RSpec.describe Flipper::Api::V1::Actions::GroupsGate do
  let(:app) { build_api(flipper) }

  describe 'enable' do
    before do
      flipper[:my_feature].disable
      Flipper.register(:admins) do |actor|
        actor.respond_to?(:admin?) && actor.admin?
      end
      post '/api/v1/features/my_feature/groups', { name: 'admins' }
    end

    it 'enables feature for group' do
      person = double
      allow(person).to receive(:flipper_id).and_return(1)
      allow(person).to receive(:admin?).and_return(true)
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].enabled?(person)).to be_truthy
    end

    it 'returns decorated feature with group enabled' do
      group_gate = json_response['gates'].find { |m| m['name'] == 'group' }
      expect(group_gate['value']).to eq(['admins'])
    end
  end

  describe 'disable' do
    before do
      flipper[:my_feature].disable
      Flipper.register(:admins) do |actor|
        actor.respond_to?(:admin?) && actor.admin?
      end
      flipper[:my_feature].enable_group(:admins)
      delete '/api/v1/features/my_feature/groups', { name: 'admins' }
    end

    it 'disables feature for group' do
      person = double
      allow(person).to receive(:flipper_id).and_return(1)
      allow(person).to receive(:admin?).and_return(true)
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].enabled?(person)).to be_falsey
    end

    it 'returns decorated feature with group disabled' do
      group_gate = json_response['gates'].find { |m| m['name'] == 'group' }
      expect(group_gate['value']).to eq([])
    end
  end

  describe 'non-existent feature' do
    before do
      delete '/api/v1/features/my_feature/groups', { name:  'admins' }
    end

    it  '404s with correct error response when feature does not exist' do
      expect(last_response.status).to eq(404)
      expect(json_response).to eq({ 'code' => 1, 'message' => 'Feature not found.', 'more_info' => '' })
    end
  end

  describe 'group not registered' do
    before do
      flipper[:my_feature].disable
      delete '/api/v1/features/my_feature/groups', { name: 'admins' }
    end

    it '404s with correct error response when group not registered' do
      expect(last_response.status).to eq(404)
      expect(json_response).to eq({ 'code' => 2, 'message' => 'Group not registered.', 'more_info' => '' })
    end
  end
end
