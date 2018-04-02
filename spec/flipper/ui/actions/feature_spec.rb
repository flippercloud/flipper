require 'helper'

RSpec.describe Flipper::UI::Actions::Feature do
  let(:token) do
    if Rack::Protection::AuthenticityToken.respond_to?(:random_token)
      Rack::Protection::AuthenticityToken.random_token
    else
      'a'
    end
  end
  let(:session) do
    { :csrf => token, 'csrf' => token, '_csrf_token' => token }
  end

  describe 'DELETE /features/:feature' do
    before do
      flipper.enable :search
      delete '/features/search',
             { 'authenticity_token' => token },
             'rack.session' => session
    end

    it 'removes feature' do
      expect(flipper.features.map(&:key)).not_to include('search')
    end

    it 'redirects to features' do
      expect(last_response.status).to be(302)
      expect(last_response.headers['Location']).to eq('/features')
    end

    context 'when feature_removal_enabled is set to false' do
      around do |example|
        begin
          @original_feature_removal_enabled = Flipper::UI.configuration.feature_removal_enabled
          Flipper::UI.configuration.feature_removal_enabled = false
          example.run
        ensure
          Flipper::UI.configuration.feature_removal_enabled = @original_feature_removal_enabled
        end
      end

      it 'returns with 403 status' do
        expect(last_response.status).to be(403)
      end

      it 'renders feature removal disabled template' do
        expect(last_response.body).to include('Feature removal from the UI is disabled')
      end
    end
  end

  describe 'POST /features/:feature with _method=DELETE' do
    before do
      flipper.enable :search
      post '/features/search',
           { '_method' => 'DELETE', 'authenticity_token' => token },
           'rack.session' => session
    end

    it 'removes feature' do
      expect(flipper.features.map(&:key)).not_to include('search')
    end

    it 'redirects to features' do
      expect(last_response.status).to be(302)
      expect(last_response.headers['Location']).to eq('/features')
    end
  end

  describe 'GET /features/:feature' do
    before do
      get '/features/search'
    end

    it 'responds with success' do
      expect(last_response.status).to be(200)
    end

    it 'renders template' do
      expect(last_response.body).to include('search')
      expect(last_response.body).to include('Enable')
      expect(last_response.body).to include('Disable')
      expect(last_response.body).to include('Actors')
      expect(last_response.body).to include('Groups')
      expect(last_response.body).to include('Percentage of Time')
      expect(last_response.body).to include('Percentage of Actors')
    end
  end
end
