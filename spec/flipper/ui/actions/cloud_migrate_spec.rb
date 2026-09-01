RSpec.describe Flipper::UI::Actions::CloudMigrate do
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

  describe "POST /settings/cloud" do
    context "when migration succeeds" do
      before do
        flipper.enable :search
        allow(Flipper::Cloud).to receive(:migrate).and_return(
          Flipper::Cloud::MigrateResult.new(code: 200, url: "https://www.flippercloud.io/cloud/setup/abc123")
        )

        post '/settings/cloud',
          {'authenticity_token' => token},
          'rack.session' => session
      end

      it 'redirects to the cloud URL' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('https://www.flippercloud.io/cloud/setup/abc123')
      end
    end

    context "when migration fails" do
      before do
        flipper.enable :search
        allow(Flipper::Cloud).to receive(:migrate).and_return(
          Flipper::Cloud::MigrateResult.new(code: 500, url: nil)
        )

        post '/settings/cloud',
          {'authenticity_token' => token},
          'rack.session' => session
      end

      it 'redirects back to settings with error' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to include('/settings')
        expect(last_response.headers['location']).to include('error=')
      end
    end
  end
end
