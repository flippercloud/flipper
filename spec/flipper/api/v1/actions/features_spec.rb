require 'helper'

RSpec.describe Flipper::Api::V1::Actions::Features do
  let(:app) { build_api(flipper) }
  let(:feature) { build_feature }
  let(:admin) { double 'Fake Fliper Thing', flipper_id: 10 }

  describe 'get' do
    context 'with flipper features' do
      before do
        flipper[:my_feature].enable
        flipper[:my_feature].enable(admin)
        get 'api/v1/features'
      end

      it 'responds with correct attributes' do
        expected_response = {
          "features" => [
            {
              "key" => "my_feature",
              "state" => "on",
              "gates" => [
                {
                  "key"=> "boolean",
                  "name"=> "boolean",
                  "value" => true
                },
                {
                  "key" => "groups",
                  "name" => "group",
                  "value" => [],
                },
                {
                  "key" => "actors",
                  "name" => "actor",
                  "value" => ["10"],
                },
                {
                  "key" => "percentage_of_actors",
                  "name" => "percentage_of_actors",
                  "value" => 0,
                },
                {
                  "key"=> "percentage_of_time",
                  "name"=> "percentage_of_time",
                  "value"=> 0,
                },
              ],
            },
          ]
        }
        expect(last_response.status).to eq(200)
        expect(json_response).to eq(expected_response)
      end
    end

    context 'with no flipper features' do
      before do
        get 'api/v1/features'
      end

      it 'returns empty array for features key' do
        expected_response = {
          "features" => []
        }
        expect(last_response.status).to eq(200)
        expect(json_response).to eq(expected_response)
      end
    end
  end

  describe 'post' do
    context 'succesful request' do
      before do
        post 'api/v1/features', { name: 'my_feature' }
      end

      it 'responds 200 ' do
        expect(last_response.status).to eq(200)
      end

      it 'returns decorated feature' do
        expected_response = {

          "key" => "my_feature",
          "state" => "off",
          "gates" => [
            {
              "key"=> "boolean",
              "name"=> "boolean",
              "value" => false,
            },
            {
              "key" => "groups",
              "name" => "group",
              "value" => [],
            },
            {
              "key" => "actors",
              "name" => "actor",
              "value" => [],
            },
            {
              "key" => "percentage_of_actors",
              "name" => "percentage_of_actors",
              "value" => 0,
            },
            {
              "key"=> "percentage_of_time",
              "name"=> "percentage_of_time",
              "value"=> 0,
            },
          ],
        }
        expect(json_response).to eq(expected_response)
      end

      it 'adds feature' do
        expect(flipper.features.map(&:key)).to include('my_feature')
      end

      it 'does not enable feature' do
        expect(flipper['my_feature'].enabled?).to be_falsy
      end
    end

    context 'bad request' do
      before do
        post 'api/v1/features'
      end

      it 'returns correct status code' do
        expect(last_response.status).to eq(422)
      end

      it 'returns formatted error' do
        expect(json_response).to eq({ 'code' => 5, 'message' => 'Required parameter name is missing.', 'more_info' => '' })
      end
    end
  end
end
