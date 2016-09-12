require 'helper'

RSpec.describe Flipper::Api::V1::Actions::Feature do
  let(:app) { build_api(flipper) }
  let(:feature) { build_feature }
  let(:gate) { feature.gate(:boolean) }

  describe 'get' do
    context 'enabled feature' do

      before do
        flipper[:my_feature].enable
        get 'api/v1/features/my_feature'
      end

      it 'responds with correct attributes' do
        response_body = {
          'key' => 'my_feature',
          'state' => 'on',
          'gates' => [
            {
              'key' => 'boolean',
              'name' => 'boolean',
              'value' => true,
            },
            {
              'key' => 'groups',
              'name' => 'group',
              'value' => [],
            },
            {
              'key' => 'actors',
              'name' => 'actor',
              'value' => [],
            },
            {
              'key' => 'percentage_of_actors',
              'name' => 'percentage_of_actors',
              'value' => 0,
            },
            {
              'key' => 'percentage_of_time',
              'name' => 'percentage_of_time',
              'value' => 0,
            }
          ]
        }

        expect(last_response.status).to eq(200)
        expect(json_response).to eq(response_body)
      end
    end

    context 'disabled feature' do
      before do
        flipper[:my_feature].disable
        get 'api/v1/features/my_feature'
      end

      it 'responds with correct attributes' do
        response_body = {
          'key' => 'my_feature',
          'state' => 'off',
          'gates' => [
            {
              'key' => 'boolean',
              'name' => 'boolean',
              'value' => false,
            },
            {
              'key'=> 'groups',
              'name'=> 'group',
              'value'=> [],
            },
            {
              'key' => 'actors',
              'name' => 'actor',
              'value' => [],
            },
            {
              'key' => 'percentage_of_actors',
              'name' => 'percentage_of_actors',
              'value'=> 0,
            },
            {
              'key' => 'percentage_of_time',
              'name' => 'percentage_of_time',
              'value' => 0,
            }
          ]
        }

        expect(last_response.status).to eq(200)
        expect(json_response).to eq(response_body)
      end
    end

    context 'feature does not exist' do
      before do
        get 'api/v1/features/not_a_feature'
      end

      it 'returns 404' do
        expect(last_response.status).to eq(404)
      end
    end
  end

  describe 'delete' do
    it 'deletes feature' do
      flipper[:my_feature].enable
      expect(flipper.features.map(&:key)).to include('my_feature')
      delete 'api/v1/features/my_feature'
      expect(last_response.status).to eq(204)
      expect(flipper.features.map(&:key)).not_to include('my_feature')
    end
  end
end
