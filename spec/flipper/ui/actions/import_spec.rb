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

  let(:path) { FlipperRoot.join("spec", "fixtures", "flipper_pstore_1679087600.json") }

  describe "POST /settings/import" do
    before do
      flipper.enable :plausible
      flipper.disable :google_analytics

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

    context "when no file is selected" do
      before do
        post '/settings/import',
          { 'authenticity_token' => token },
          'rack.session' => session
      end

      it 'redirects to settings with an error' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/settings?error=You+must+select+a+file+to+import.')
      end
    end

    context "when the file is too large" do
      before do
        stub_const("Flipper::Exporters::Json::Export::MAX_BYTES", 1)

        post '/settings/import',
          {
            'authenticity_token' => token,
            'file' => Rack::Test::UploadedFile.new(path, "application/json"),
          },
          'rack.session' => session
      end

      it 'redirects to settings with an error' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/settings?error=The+import+file+is+too+large+to+import.')
      end
    end

    context "when the file is invalid" do
      before do
        post '/settings/import',
          {
            'authenticity_token' => token,
            'file' => Rack::Test::UploadedFile.new(StringIO.new("not json"), "flipper.json", original_filename: "flipper.json"),
          },
          'rack.session' => session
      end

      it 'redirects to settings with an error' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/settings?error=The+import+file+is+invalid.')
      end
    end

    context "when in read only mode" do
      before do
        allow(flipper).to receive(:read_only?) { true }

        post '/settings/import',
          {
            'authenticity_token' => token,
            'file' => Rack::Test::UploadedFile.new(path, "application/json"),
          },
          'rack.session' => session
      end

      it 'returns 403' do
        expect(last_response.status).to be(403)
      end

      it 'renders read only template' do
        expect(last_response.body).to include('read only')
      end
    end
  end
end
