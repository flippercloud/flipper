RSpec.describe Flipper::UI::Actions::ActorsGate do
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

  describe 'GET /features/:feature/denied_actors' do
    before do
      get 'features/search/denied_actors'
    end

    it 'responds with success' do
      expect(last_response.status).to be(200)
    end

    it 'renders add new denied actor form' do
      form = '<form action="/features/search/denied_actors" method="post" class="form-inline">'
      expect(last_response.body).to include(form)
    end
  end

  describe 'GET /features/:feature/denied_actors with slash in feature name' do
    before do
      get 'features/a/b/denied_actors'
    end

    it 'responds with success' do
      expect(last_response.status).to be(200)
    end

    it 'renders add new actor form' do
      form = '<form action="/features/a/b/denied_actors" method="post" class="form-inline">'
      expect(last_response.body).to include(form)
    end
  end

  describe 'POST /features/:feature/denied_actors' do
    context 'denying an actor' do
      let(:value) { 'User;6' }
      let(:multi_value) { 'User;5, User;7, User;9, User;12' }

      before do
        post 'features/search/denied_actors',
             { 'value' => value, 'operation' => 'deny', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'adds item to members' do
        expect(flipper[:search].denied_actors_value).to include(value)
      end

      it 'adds item to multiple members' do
        post 'features/search/denied_actors',
             { 'value' => multi_value, 'operation' => 'deny', 'authenticity_token' => token },
             'rack.session' => session

        expect(flipper[:search].denied_actors_value).to include('User;5')
        expect(flipper[:search].denied_actors_value).to include('User;7')
        expect(flipper[:search].denied_actors_value).to include('User;9')
        expect(flipper[:search].denied_actors_value).to include('User;12')
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['Location']).to eq('/features/search')
      end

      context "when feature name contains space" do
        before do
          post 'features/sp%20ace/denied_actors',
               { 'value' => value, 'operation' => 'deny', 'authenticity_token' => token },
               'rack.session' => session
        end

        it 'adds item to members' do
          expect(flipper["sp ace"].denied_actors_value).to include('User;6')
        end

        it "redirects back to feature" do
          expect(last_response.status).to be(302)
          expect(last_response.headers['Location']).to eq('/features/sp%20ace')
        end
      end

      context 'value contains whitespace' do
        let(:value) { '  User;6  ' }
        let(:multi_value) { '  User;5  ,  User;7   ,  User;9 ,  User;12 ' }

        it 'adds item without whitespace' do
          expect(flipper[:search].denied_actors_value).to include('User;6')
        end

        it 'adds item to multi members without whitespace' do
          post 'features/search/denied_actors',
             { 'value' => multi_value, 'operation' => 'deny', 'authenticity_token' => token },
             'rack.session' => session

          expect(flipper[:search].denied_actors_value).to include('User;5')
          expect(flipper[:search].denied_actors_value).to include('User;7')
          expect(flipper[:search].denied_actors_value).to include('User;9')
          expect(flipper[:search].denied_actors_value).to include('User;12')
        end
      end

      context 'for an invalid actor value' do
        context 'empty value' do
          let(:value) { '' }

          it 'redirects to denied actors page' do
            expect(last_response.status).to be(302)
            expect(last_response.headers['Location']).to eq('/features/search/denied_actors?error=%22%22%20is%20not%20a%20valid%20actor%20value.')
          end
        end

        context 'nil value' do
          let(:value) { nil }

          it 'redirects to denied actors page' do
            expect(last_response.status).to be(302)
            expect(last_response.headers['Location']).to eq('/features/search/denied_actors?error=%22%22%20is%20not%20a%20valid%20actor%20value.')
          end
        end
      end
    end

    context 'reinstating an actor' do
      let(:value) { 'User;6' }
      let(:multi_value) { 'User;5, User;7, User;9, User;12' }

      before do
        flipper[:search].deny_actor Flipper::Actor.new(value)
        post 'features/search/denied_actors',
             { 'value' => value, 'operation' => 'reinstate', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'removes item from members' do
        expect(flipper[:search].denied_actors_value).not_to include(value)
      end

      it 'removes item from multi members' do
        multi_value.split(',').map(&:strip).each do |value|
          flipper[:search].deny_actor Flipper::Actor.new(value)
        end

        post 'features/search/denied_actors',
             { 'value' => multi_value, 'operation' => 'reinstate', 'authenticity_token' => token },
             'rack.session' => session

        expect(flipper[:search].denied_actors_value).not_to eq(Set.new(multi_value.split(',').map(&:strip)))
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['Location']).to eq('/features/search')
      end

      context 'value contains whitespace' do
        let(:value) { '  User;6  ' }
        let(:multi_value) { '  User;5  ,  User;7   ,  User;9 ,  User;12 ' }

        it 'removes item without whitespace' do
          expect(flipper[:search].denied_actors_value).not_to include('User;6')
        end

        it 'removes item without whitespace' do
          multi_value.split(',').map(&:strip).each do |value|
            flipper[:search].deny_actor Flipper::Actor.new(value)
          end
          post 'features/search/denied_actors',
              { 'value' => multi_value, 'operation' => 'reinstate', 'authenticity_token' => token },
              'rack.session' => session
          expect(flipper[:search].denied_actors_value).not_to eq(Set.new(multi_value.split(',').map(&:strip)))
        end
      end
    end
  end
end
