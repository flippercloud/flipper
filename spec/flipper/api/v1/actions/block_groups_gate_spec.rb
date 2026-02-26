RSpec.describe Flipper::Api::V1::Actions::BlockGroupsGate do
  let(:app) { build_api(flipper) }

  describe 'block' do
    before do
      Flipper.register(:admins) do |actor|
        actor.respond_to?(:admin?) && actor.admin?
      end
      post '/features/my_feature/block_groups', name: 'admins'
    end

    it 'blocks group for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].block_groups_value).to include('admins')
    end

    it 'returns decorated feature with block_groups gate' do
      group_gate = json_response['gates'].find { |m| m['key'] == 'block_groups' }
      expect(group_gate['value']).to eq(['admins'])
    end
  end

  describe 'block feature with slash in name' do
    before do
      Flipper.register(:admins) do |actor|
        actor.respond_to?(:admin?) && actor.admin?
      end
      post '/features/my/feature/block_groups', name: 'admins'
    end

    it 'blocks group for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper["my/feature"].block_groups_value).to include('admins')
    end

    it 'returns decorated feature with block_groups gate' do
      group_gate = json_response['gates'].find { |m| m['key'] == 'block_groups' }
      expect(group_gate['value']).to eq(['admins'])
    end
  end

  describe 'block without name params' do
    before do
      post '/features/my_feature/block_groups'
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

  describe 'unblock' do
    before do
      Flipper.register(:admins) do |actor|
        actor.respond_to?(:admin?) && actor.admin?
      end
      flipper[:my_feature].block_group(:admins)
      delete '/features/my_feature/block_groups', name: 'admins'
    end

    it 'unblocks group for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].block_groups_value).to be_empty
    end

    it 'returns decorated feature with empty block_groups gate' do
      group_gate = json_response['gates'].find { |m| m['key'] == 'block_groups' }
      expect(group_gate['value']).to eq([])
    end
  end

  describe 'unblock for group not registered' do
    before do
      delete '/features/my_feature/block_groups', name: 'admins'
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

  describe 'block for group not registered when allow_unregistered_groups is true' do
    before do
      Flipper.unregister_groups
      post '/features/my_feature/block_groups', name: 'admins', allow_unregistered_groups: 'true'
    end

    it 'responds successfully' do
      expect(last_response.status).to eq(200)
    end

    it 'returns decorated feature with group in block_groups set' do
      group_gate = json_response['gates'].find { |m| m['key'] == 'block_groups' }
      expect(group_gate['value']).to eq(['admins'])
    end

    it 'blocks group' do
      expect(flipper[:my_feature].block_groups_value).to eq(Set["admins"])
    end
  end

  describe 'unblock for group not registered when allow_unregistered_groups is true' do
    before do
      Flipper.unregister_groups
      flipper[:my_feature].block_group(:admins)
      delete '/features/my_feature/block_groups', name: 'admins', allow_unregistered_groups: 'true'
    end

    it 'responds successfully' do
      expect(last_response.status).to eq(200)
    end

    it 'returns decorated feature with group not in block_groups set' do
      group_gate = json_response['gates'].find { |m| m['key'] == 'block_groups' }
      expect(group_gate['value']).to eq([])
    end

    it 'unblocks group' do
      expect(flipper[:my_feature].block_groups_value).to be_empty
    end
  end
end
