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
      expect(last_response.headers['location']).to eq('/features')
    end

    context "with space in feature name" do
      before do
        flipper.enable "sp ace"
        delete '/features/sp%20ace',
               { 'authenticity_token' => token },
               'rack.session' => session
      end

      it 'removes feature' do
        expect(flipper.features.map(&:key)).not_to include('sp ace')
      end

      it 'redirects to features' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features')
      end
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
      expect(last_response.headers['location']).to eq('/features')
    end
  end

  describe 'GET /features/:feature' do
    before do
      Flipper::UI.configure do |config|
        config.descriptions_source = lambda { |_keys|
          {
            "stats" => "Most awesome stats",
            "search" => "Most in-depth search",
          }
        }
      end

      get '/features/search'
    end

    it 'responds with success' do
      expect(last_response.status).to be(200)
    end

    it 'renders template' do
      expect(last_response.body).to include('search')
      expect(last_response.body).to include('Enable')
      expect(last_response.body).to include('Disable')
      expect(last_response.body).to include('No actors enabled')
      expect(last_response.body).to include('No groups enabled')
      expect(last_response.body).to include('Enabled for 0% of time')
      expect(last_response.body).to include('Enabled for 0% of actors')
      expect(last_response.body).to include('Most in-depth search')
    end

    context "when in read-only mode" do
      before do
        allow(flipper).to receive(:read_only?) { true }
      end

      before { get '/features' }

      it 'renders template with no buttons or ways to modify a feature' do
        expect(last_response.body).not_to include("Fully Enable")
      end
    end

    context 'custom actor names' do
      before do
        actor = Flipper::Actor.new('some_actor_name')
        flipper['search'].enable_actor(actor)

        Flipper::UI.configure do |config|
          config.actor_names_source = lambda { |_keys|
            {
              "some_actor_name" => "Some Actor Name",
              "some_other_actor_name" => "Some Other Actor Name",
            }
          }
        end
      end

      it 'renders template with custom actor names' do
        get '/features/search'
        expect(last_response.body).to include('Some Actor Name (some_actor_name)')
        expect(last_response.body).not_to include('Some Other Actor Name')
      end

      it 'allows basic html' do
        Flipper::UI.configure do |config|
          config.actor_names_source = lambda { |_keys|
            { "some_actor_name" => '<a href="/users/some_actor_name">Some Actor Name</a>', }
          }
        end

        get '/features/search'
        expect(last_response.body).to include('<a href="/users/some_actor_name" rel="nofollow">Some Actor Name</a>')
      end

      it 'sanitizes dangerous markup' do
        Flipper::UI.configure do |config|
          config.actor_names_source = lambda { |_keys|
            { "some_actor_name" => '<a href="javascript:alert(\'hello\')">Some Actor Name</a>', }
          }
        end

        get '/features/search'
        expect(last_response.body).not_to include('javascript:alert')
      end
    end

    context 'with expressions enabled' do
      before do
        allow(Flipper::UI.configuration).to receive(:expressions_enabled).and_return(true)
      end

      context 'with expression enabled on feature' do
        before do
          expression = Flipper::Expression.build({
            "Any" => [
              {"Equal" => [{"Property" => ["userId"]}, {"String" => ["123"]}]},
              {"All" => [
                {"GreaterThan" => [{"Property" => ["age"]}, {"Number" => [18]}]},
                {"LessThan" => [{"Now" => []}, {"Time" => ["2025-12-31T23:59:59Z"]}]}
              ]},
              {"GreaterThanOrEqualTo" => [{"Percentage" => [50]}, {"Number" => [50]}]},
              {"LessThanOrEqualTo" => [{"Random" => [100]}, {"Number" => [0.75]}]},
              {"NotEqual" => [{"Property" => ["role"]}, {"String" => ["guest"]}]},
              {"PercentageOfActors" => ["User;1", 50 ]},
              {"Boolean" => [true]},
              {"Duration" => ["1", "days"]}
            ]
          })
          flipper[:search].enable_expression(expression)
        end

        it 'shows expression is enabled in feature view' do
          get '/features/search'
          expect(last_response.status).to be(200)
          expect(last_response.body).to include('Enabled for actors where')
        end
      end
    end

    context 'with expressions disabled' do
      before do
        allow(Flipper::UI.configuration).to receive(:expressions_enabled).and_return(false)
      end

      it 'does not show expression section when expressions are disabled' do
        get '/features/search'
        expect(last_response.status).to be(200)
        expect(last_response.body).not_to include('No expression enabled')
        expect(last_response.body).not_to include('Add an expression')
      end
    end
  end

  describe 'GET /features/:feature with _features in feature name' do
    before do
      get '/features/search_features'
    end

    it 'responds with success' do
      expect(last_response.status).to be(200)
    end

    it 'renders template' do
      expect(last_response.body).to include('search_features')
    end
  end

  describe 'GET /features/:feature with slash in feature name' do
    before do
      get '/features/a/b'
    end

    it 'responds with success' do
      expect(last_response.status).to be(200)
    end

    it 'renders template' do
      expect(last_response.body).to include('a/b')
    end
  end

  describe 'GET /features/:feature with dot dot slash repeated in feature name' do
    before do
      get '/features/..%2F..%2F..%2F..%2Fblah'
    end

    it 'responds with success' do
      expect(last_response.status).to be(200)
    end

    it 'renders template' do
      expect(last_response.body).to include('../../../../blah')
    end
  end
end
