RSpec.describe Flipper::UI::Actions::Settings do
  describe 'GET /settings' do
    before do
      get '/settings'
    end

    it 'responds with success' do
      expect(last_response.status).to be(200)
    end

    it 'renders template' do
      expect(last_response.body).to include('Download')
    end

    it 'includes migrate to Flipper Cloud card' do
      expect(last_response.body).to include('Migrate to Flipper Cloud')
    end

    it 'shows feature count' do
      expect(last_response.body).to include('features ready to migrate')
    end
  end

  describe 'GET /settings with cloud_recommendation disabled' do
    before do
      @original_cloud_recommendation = Flipper::UI.configuration.cloud_recommendation
      Flipper::UI.configuration.cloud_recommendation = false
      get '/settings'
    end

    after do
      Flipper::UI.configuration.cloud_recommendation = @original_cloud_recommendation
    end

    it 'responds with success' do
      expect(last_response.status).to be(200)
    end

    it 'does not include migrate to Flipper Cloud card' do
      expect(last_response.body).not_to include('Migrate to Flipper Cloud')
    end
  end
end
