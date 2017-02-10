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
              'value' => "true",
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
              'value' => nil,
            },
            {
              'key' => 'percentage_of_time',
              'name' => 'percentage_of_time',
              'value' => nil,
            },
          ],
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
              'value' => nil,
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
              'value' => nil,
            },
            {
              'key' => 'percentage_of_time',
              'name' => 'percentage_of_time',
              'value' => nil,
            },
          ],
        }

        expect(last_response.status).to eq(200)
        expect(json_response).to eq(response_body)
      end
    end

    context 'feature does not exist' do
      before do
        get 'api/v1/features/not_a_feature'
      end

      it 'responds with correct attributes' do
        response_body = {
          'key' => 'not_a_feature',
          'state' => 'off',
          'gates' => [
            {
              'key' => 'boolean',
              'name' => 'boolean',
              'value' => nil,
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
              'value' => nil,
            },
            {
              'key' => 'percentage_of_time',
              'name' => 'percentage_of_time',
              'value' => nil,
            },
          ],
        }

        expect(last_response.status).to eq(200)
        expect(json_response).to eq(response_body)
      end
    end
  end

  describe 'delete' do
    context 'succesful request' do
      it 'deletes feature' do
        flipper[:my_feature].enable
        expect(flipper.features.map(&:key)).to include('my_feature')
        delete 'api/v1/features/my_feature'
        expect(last_response.status).to eq(204)
        expect(flipper.features.map(&:key)).not_to include('my_feature')
      end
    end

    context 'feature not found' do
      before do
        delete 'api/v1/features/my_feature'
      end

      it 'responds with 204' do
        expect(last_response.status).to eq(204)
        expect(flipper.features.map(&:key)).not_to include('my_feature')
      end
    end
  end
end
