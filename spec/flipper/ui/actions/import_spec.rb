RSpec.describe Flipper::UI::Actions::Import do
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

  describe "POST /settings/import" do
    before do
      flipper.enable :plausible
      flipper.disable :google_analytics
      path = FlipperRoot.join("spec", "fixtures", "flipper_pstore_1679087600.json")

      post '/settings/import',
        {
          'authenticity_token' => token,
          'file' => Rack::Test::UploadedFile.new(path, "application/json"),
        },
        'rack.session' => session
    end

    it 'imports the file export' do
      expect(flipper[:search].actors_value).to eq(Set.new(['john', 'another', 'testing']))
      expect(flipper[:search].groups_value).to eq(Set.new(['admins']))
      expect(flipper[:google_analytics_tag].percentage_of_actors_value).to eq(100)
      expect(flipper[:new_pricing].boolean_value).to eq(true)
      expect(flipper[:nope].boolean_value).to eq(false)
    end

    it 'responds with redirect to settings' do
      expect(last_response.status).to be(302)
      expect(last_response.headers['location']).to eq('/features')
    end
  end
end
