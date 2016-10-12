require 'helper'

RSpec.describe Flipper::Api::V1::Actions::BooleanGate do
  let(:app) { build_api(flipper) }

  describe 'enable' do
    before do
      flipper[:my_feature].disable
      post '/api/v1/features/my_feature/boolean'
    end

    it 'enables feature' do
      expect(last_response.status).to eq(204)
      expect(flipper[:my_feature].on?).to be_truthy
    end
  end

  describe 'disable' do
    before do
      flipper[:my_feature].enable
      delete '/api/v1/features/my_feature/boolean'
    end

    it 'disables feature' do
      expect(last_response.status).to eq(204)
      expect(flipper[:my_feature].off?).to be_truthy
    end
  end
end
