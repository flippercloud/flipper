require 'helper'
RSpec.describe Flipper::Api::Actions::Features do
  describe 'GET /alex' do
    let(:app) { build_api(flipper) }

    context 'valid route' do
      before do
        flipper[:buddy_list].enable
        flipper[:messenger].enable
        get '/api/v1/features/'
      end

      it 'returns features' do
        expected_res = {
          'features' => [
            {
              'key' => 'buddy_list', 
              'name' => 'buddy_list'
            },
              'key' => 'messenger',
              'name' => 'messenger'
          ]
        }
        expect(last_response.status).to eq(200)
        expect(json_response).to eq(expected_res)
      end
    end
  end
end
