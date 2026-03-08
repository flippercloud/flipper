RSpec.describe Flipper::Api::V1::Actions::DenyGroupsGate do
  let(:app) { build_api(flipper) }

  describe 'deny' do
    before do
      Flipper.register(:admins) do |actor|
        actor.respond_to?(:admin?) && actor.admin?
      end
      post '/features/my_feature/deny_groups', name: 'admins'
    end

    it 'denies group for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].deny_groups_value).to include('admins')
    end

    it 'returns decorated feature with deny_groups gate' do
      group_gate = json_response['gates'].find { |m| m['key'] == 'deny_groups' }
      expect(group_gate['value']).to eq(['admins'])
    end
  end

  describe 'deny feature with slash in name' do
    before do
      Flipper.register(:admins) do |actor|
        actor.respond_to?(:admin?) && actor.admin?
      end
      post '/features/my/feature/deny_groups', name: 'admins'
    end

    it 'denies group for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper["my/feature"].deny_groups_value).to include('admins')
    end

    it 'returns decorated feature with deny_groups gate' do
      group_gate = json_response['gates'].find { |m| m['key'] == 'deny_groups' }
      expect(group_gate['value']).to eq(['admins'])
    end
  end

  describe 'deny without name params' do
    before do
      post '/features/my_feature/deny_groups'
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

  describe 'permit' do
    before do
      Flipper.register(:admins) do |actor|
        actor.respond_to?(:admin?) && actor.admin?
      end
      flipper[:my_feature].deny_group(:admins)
      delete '/features/my_feature/deny_groups', name: 'admins'
    end

    it 'undenies group for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].deny_groups_value).to be_empty
    end

    it 'returns decorated feature with empty deny_groups gate' do
      group_gate = json_response['gates'].find { |m| m['key'] == 'deny_groups' }
      expect(group_gate['value']).to eq([])
    end
  end

  describe 'permit for group not registered' do
    before do
      delete '/features/my_feature/deny_groups', name: 'admins'
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

  describe 'deny for group not registered when allow_unregistered_groups is true' do
    before do
      Flipper.unregister_groups
      post '/features/my_feature/deny_groups', name: 'admins', allow_unregistered_groups: 'true'
    end

    it 'responds successfully' do
      expect(last_response.status).to eq(200)
    end

    it 'returns decorated feature with group in deny_groups set' do
      group_gate = json_response['gates'].find { |m| m['key'] == 'deny_groups' }
      expect(group_gate['value']).to eq(['admins'])
    end

    it 'denies group' do
      expect(flipper[:my_feature].deny_groups_value).to eq(Set["admins"])
    end
  end

  describe 'permit for group not registered when allow_unregistered_groups is true' do
    before do
      Flipper.unregister_groups
      flipper[:my_feature].deny_group(:admins)
      delete '/features/my_feature/deny_groups', name: 'admins', allow_unregistered_groups: 'true'
    end

    it 'responds successfully' do
      expect(last_response.status).to eq(200)
    end

    it 'returns decorated feature with group not in deny_groups set' do
      group_gate = json_response['gates'].find { |m| m['key'] == 'deny_groups' }
      expect(group_gate['value']).to eq([])
    end

    it 'undenies group' do
      expect(flipper[:my_feature].deny_groups_value).to be_empty
    end
  end
end
