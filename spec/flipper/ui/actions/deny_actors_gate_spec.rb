RSpec.describe Flipper::UI::Actions::DenyActorsGate do
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

  describe 'POST /features/:feature/deny_actors' do
    context 'denying an actor' do
      let(:value) { 'User;6' }
      let(:multi_value) { 'User;5, User;7, User;9, User;12' }

      before do
        post 'features/search/deny_actors',
             { 'value' => value, 'operation' => 'deny', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'adds item to denied actors' do
        expect(flipper[:search].deny_actors_value).to include(value)
      end

      it 'adds multiple items to denied actors' do
        post 'features/search/deny_actors',
             { 'value' => multi_value, 'operation' => 'deny', 'authenticity_token' => token },
             'rack.session' => session

        expect(flipper[:search].deny_actors_value).to include('User;5')
        expect(flipper[:search].deny_actors_value).to include('User;7')
        expect(flipper[:search].deny_actors_value).to include('User;9')
        expect(flipper[:search].deny_actors_value).to include('User;12')
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/search')
      end

      context 'when feature name contains space' do
        before do
          post 'features/sp+ace/deny_actors',
               { 'value' => value, 'operation' => 'deny', 'authenticity_token' => token },
               'rack.session' => session
        end

        it 'adds item to denied actors' do
          expect(flipper["sp ace"].deny_actors_value).to include('User;6')
        end

        it 'redirects back to feature' do
          expect(last_response.status).to be(302)
          expect(last_response.headers['location']).to eq('/features/sp+ace')
        end
      end

      context 'value contains whitespace' do
        let(:value) { '  User;6  ' }

        it 'adds item without whitespace' do
          expect(flipper[:search].deny_actors_value).to include('User;6')
        end
      end

      context 'for an invalid actor value' do
        context 'empty value' do
          let(:value) { '' }

          it 'redirects back with error' do
            expect(last_response.status).to be(302)
            expect(last_response.headers['location']).to eq('/features/search/deny_actors?error=%22%22+is+not+a+valid+actor+value.')
          end
        end

        context 'nil value' do
          let(:value) { nil }

          it 'redirects back with error' do
            expect(last_response.status).to be(302)
            expect(last_response.headers['location']).to eq('/features/search/deny_actors?error=%22%22+is+not+a+valid+actor+value.')
          end
        end
      end
    end

    context 'when a readonly adapter is configured' do
      let(:value) { 'User;6' }

      before do
        allow(flipper).to receive(:read_only?) { true }
      end

      it 'does not allow an actor to be denied' do
        post 'features/search/deny_actors',
           { 'value' => value, 'operation' => 'deny', 'authenticity_token' => token },
           'rack.session' => session

        expect(flipper[:search].deny_actors_value).not_to include('User;6')
        expect(last_response.body).to include("The UI is currently in read only mode.")
      end
    end

    context 'permitting an actor' do
      let(:value) { 'User;6' }

      before do
        flipper[:search].deny_actor Flipper::Actor.new(value)
        post 'features/search/deny_actors',
             { 'value' => value, 'operation' => 'permit', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'removes item from denied actors' do
        expect(flipper[:search].deny_actors_value).not_to include(value)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/search')
      end

      context 'value contains whitespace' do
        let(:value) { '  User;6  ' }

        it 'removes item without whitespace' do
          expect(flipper[:search].deny_actors_value).not_to include('User;6')
        end
      end
    end
  end
end
