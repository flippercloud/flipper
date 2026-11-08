RSpec.describe Flipper::UI::Actions::PercentageOfActorsGate do
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

  describe 'POST /features/:feature/percentage_of_actors' do
    # Regression: ISSUE-001, reserved names showed an invalid percentage error.
    context 'with a reserved feature name' do
      before do
        post 'features/__flipper_thing/percentage_of_actors',
             { 'value' => '24', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'does not enable the feature' do
        expect(flipper.features).to be_empty
      end

      it 'redirects back to the feature with the reserved name error' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/__flipper_thing?error=%22__flipper_thing%22+is+reserved+for+Flipper%27s+internal+use.')
      end
    end

    context 'with valid value' do
      before do
        post 'features/search/percentage_of_actors',
             { 'value' => '24', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'enables the feature' do
        expect(flipper[:search].percentage_of_actors_value).to be(24)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/search')
      end
    end

    context 'with space in feature name' do
      before do
        post 'features/sp+ace/percentage_of_actors',
             { 'value' => '24', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'enables the feature' do
        expect(flipper["sp ace"].percentage_of_actors_value).to be(24)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/sp+ace')
      end
    end

    context 'with invalid value' do
      before do
        post 'features/search/percentage_of_actors',
             { 'value' => '555', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'does not change value' do
        expect(flipper[:search].percentage_of_actors_value).to be(0)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/search?error=Invalid+percentage+of+actors+value%3A+value+must+be+a+positive+number+less+than+or+equal+to+100%2C+but+was+555')
      end
    end
  end
end
