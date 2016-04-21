require 'helper'

RSpec.describe Flipper::Api::V1::Actions::BooleanGate do
  let(:app) { build_api(flipper) }

  describe 'enable' do
    before do
      flipper[:my_feature].disable
      put '/api/v1/features/my_feature/enable'
    end

    it 'enables feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].on?).to be_truthy
    end
  end

  describe 'disable' do
    before do
      flipper[:my_feature].enable
      put '/api/v1/features/my_feature/disable'
    end

    it 'disables feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].off?).to be_truthy
    end
  end

  describe 'invalid paremeter' do
    before do
      put '/api/v1/features/my_feature/invalid_param'
    end

    it 'responds with 404 when not sent enable or disable parameter' do
      expect(last_response.status).to eq(404)
    end
  end
end
