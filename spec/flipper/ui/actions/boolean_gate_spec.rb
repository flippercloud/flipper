RSpec.describe Flipper::UI::Actions::BooleanGate do
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

  describe 'POST /features/:feature/boolean' do
    context 'with a reserved feature name' do
      before do
        post 'features/__flipper_thing/boolean',
             { 'action' => 'Enable', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'does not enable the feature' do
        expect(flipper.features).to be_empty
      end

      it 'redirects back to the feature with an error' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/__flipper_thing?error=%22__flipper_thing%22+is+reserved+for+Flipper%27s+internal+use.')
      end
    end

    context 'with enable' do
      before do
        flipper.disable :search
        post 'features/search/boolean',
             { 'action' => 'Enable', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'enables the feature' do
        expect(flipper.enabled?(:search)).to be(true)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/search')
      end
    end

    context "with space in feature name" do
      before do
        flipper.disable :search
        post 'features/sp%20ace/boolean',
             { 'action' => 'Enable', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'updates feature' do
        expect(flipper.enabled?("sp ace")).to be(true)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/sp+ace')
      end
    end

    context 'with disable' do
      before do
        flipper.enable :search
        post 'features/search/boolean',
             { 'action' => 'Disable', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'disables the feature' do
        expect(flipper.enabled?(:search)).to be(false)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/search')
      end
    end

    context 'when disable_fully_enable is false' do
      before { Flipper::UI.configuration.disable_fully_enable = false }
      after { Flipper::UI.configuration.disable_fully_enable = nil }

      it 'allows enabling the feature' do
        flipper.disable :search
        post 'features/search/boolean',
             { 'action' => 'Enable', 'authenticity_token' => token },
             'rack.session' => session
        expect(flipper.enabled?(:search)).to be(true)
      end
    end

    context 'when disable_fully_enable is true' do
      before { Flipper::UI.configuration.disable_fully_enable = true }
      after { Flipper::UI.configuration.disable_fully_enable = nil }

      context 'with enable' do
        before do
          flipper.disable :search
          post 'features/search/boolean',
               { 'action' => 'Enable', 'authenticity_token' => token },
               'rack.session' => session
        end

        it 'does not enable the feature' do
          expect(flipper.enabled?(:search)).to be(false)
        end

        it 'returns 403 status' do
          expect(last_response.status).to be(403)
        end

        it 'renders the default disabled message' do
          expect(last_response.body).to include('Fully enabling features via the UI is disabled.')
        end
      end

      context 'with disable' do
        before do
          flipper.enable :search
          post 'features/search/boolean',
               { 'action' => 'Disable', 'authenticity_token' => token },
               'rack.session' => session
        end

        it 'still allows disabling the feature' do
          expect(flipper.enabled?(:search)).to be(false)
        end

        it 'redirects back to feature' do
          expect(last_response.status).to be(302)
          expect(last_response.headers['location']).to eq('/features/search')
        end
      end
    end

    context 'when disable_fully_enable is a custom message' do
      before { Flipper::UI.configuration.disable_fully_enable = "Use deploy pipeline instead." }
      after { Flipper::UI.configuration.disable_fully_enable = nil }

      it 'renders the custom message on 403' do
        flipper.disable :search
        post 'features/search/boolean',
             { 'action' => 'Enable', 'authenticity_token' => token },
             'rack.session' => session
        expect(last_response.status).to be(403)
        expect(last_response.body).to include('Use deploy pipeline instead.')
      end
    end
  end
end
