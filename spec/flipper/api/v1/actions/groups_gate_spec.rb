RSpec.describe Flipper::Api::V1::Actions::GroupsGate do
  let(:app) { build_api(flipper) }

  describe 'enable' do
    before do
      flipper[:my_feature].disable
      Flipper.register(:admins) do |actor|
        actor.respond_to?(:admin?) && actor.admin?
      end
      post '/features/my_feature/groups', name: 'admins'
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

  describe 'enable feature with slash in name' do
    before do
      flipper["my/feature"].disable
      Flipper.register(:admins) do |actor|
        actor.respond_to?(:admin?) && actor.admin?
      end
      post '/features/my/feature/groups', name: 'admins'
    end

    it 'enables feature for group' do
      person = double
      allow(person).to receive(:flipper_id).and_return(1)
      allow(person).to receive(:admin?).and_return(true)
      expect(last_response.status).to eq(200)
      expect(flipper["my/feature"].enabled?(person)).to be_truthy
    end

    it 'returns decorated feature with group enabled' do
      group_gate = json_response['gates'].find { |m| m['name'] == 'group' }
      expect(group_gate['value']).to eq(['admins'])
    end
  end

  describe 'enable without name params' do
    before do
      flipper[:my_feature].disable
      Flipper.register(:admins) do |actor|
        actor.respond_to?(:admin?) && actor.admin?
      end
      post '/features/my_feature/groups'
    end

    it 'returns correct status code' do
      expect(last_response.status).to eq(422)
    end

    it 'returns formatted error' do
      expected = {
        'code' => 5,
        'message' => 'Required parameter name is missing.',
        'more_info' => api_error_code_reference_url,
      }
      expect(json_response).to eq(expected)
    end
  end

  describe 'disable' do
    before do
      flipper[:my_feature].disable
      Flipper.register(:admins) do |actor|
        actor.respond_to?(:admin?) && actor.admin?
      end
      flipper[:my_feature].enable_group(:admins)
      delete '/features/my_feature/groups', name: 'admins'
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

  describe 'disable for non-existent feature' do
    before do
      Flipper.register(:admins) do |actor|
        actor.respond_to?(:admin?) && actor.admin?
      end
      delete '/features/my_feature/groups', name: 'admins'
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

  describe 'disable for group not registered' do
    before do
      flipper[:my_feature].disable
      delete '/features/my_feature/groups', name: 'admins'
    end

    it '404s with correct error response when group not registered' do
      expect(last_response.status).to eq(404)
      expected = {
        'code' => 2,
        'message' => 'Group not registered.',
        'more_info' => api_error_code_reference_url,
      }
      expect(json_response).to eq(expected)
    end
  end

  describe 'enable for group not registered when allow_unregistered_groups is true' do
    before do
      Flipper.unregister_groups
      flipper[:my_feature].disable
      post '/features/my_feature/groups', name: 'admins', allow_unregistered_groups: 'true'
    end

    it 'responds successfully' do
      expect(last_response.status).to eq(200)
    end

    it 'returns decorated feature with group in groups set' do
      group_gate = json_response['gates'].find { |m| m['name'] == 'group' }
      expect(group_gate['value']).to eq(['admins'])
    end

    it 'enables group' do
      expect(flipper[:my_feature].groups_value).to eq(Set["admins"])
    end
  end

  describe 'disable for group not registered when allow_unregistered_groups is true' do
    before do
      Flipper.unregister_groups
      flipper[:my_feature].disable
      flipper[:my_feature].enable_group(:admins)
      delete '/features/my_feature/groups', name: 'admins', allow_unregistered_groups: 'true'
    end

    it 'responds successfully' do
      expect(last_response.status).to eq(200)
    end

    it 'returns decorated feature with group not in groups set' do
      group_gate = json_response['gates'].find { |m| m['name'] == 'group' }
      expect(group_gate['value']).to eq([])
    end

    it 'disables group' do
      expect(flipper[:my_feature].groups_value).to be_empty
    end
  end
end
