RSpec.describe Flipper::UI do
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
  let(:configuration) { described_class.configuration }

  describe 'Initializing middleware with flipper instance' do
    let(:app) { build_app(flipper) }

    it 'works' do
      flipper.enable :some_great_feature
      get '/features'
      expect(last_response.status).to be(200)
      expect(last_response.body).to include('some_great_feature')
    end
  end

  describe 'Request method unsupported by action' do
    it 'raises error' do
      expect do
        head '/features'
      end.to raise_error(Flipper::UI::RequestMethodNotSupported)
    end
  end

  describe 'Inspecting the built Rack app' do
    it 'returns a String' do
      expect(build_app(flipper).inspect).to eq("Flipper::UI")
    end
  end

  # See https://github.com/flippercloud/flipper/issues/80
  it 'can route features with names that match static directories' do
    post 'features/refactor-images/actors',
         { 'value' => 'User;6', 'operation' => 'enable', 'authenticity_token' => token },
         'rack.session' => session
    expect(last_response.status).to be(302)
    expect(last_response.headers['location']).to eq('/features/refactor-images')
  end

  describe 'configure' do
    it 'yields configuration instance' do
      described_class.configure do |config|
        expect(config).to be_instance_of(Flipper::UI::Configuration)
      end
    end

    describe 'banner' do
      it 'does not include the banner if banner_text is not set' do
        get '/features'
        expect(last_response.body).not_to include('Production Environment')
      end

      describe 'when set' do
        around do |example|
          begin
            @original_banner_text = described_class.configuration.banner_text
            described_class.configuration.banner_text = 'Production Environment'
            example.run
          ensure
            described_class.configuration.banner_text = @original_banner_text
          end
        end

        it 'includes banner' do
          get '/features'
          expect(last_response.body).to include('Production Environment')
        end
      end
    end

    describe "application_href" do
      around do |example|
        original_href = configuration.application_href
        example.run
      ensure
        configuration.application_href = original_href
      end

      it 'does not have an application_href by default' do
        expect(configuration.application_href).to be(nil)
      end

      context 'with application_href not set' do
        it 'does not add App link' do
          get '/features'
          expect(last_response.body).not_to include('<a href="/myapp">App</a>')
        end
      end

      context 'with application_href set' do
        before do
          configuration.application_href = '/myapp'
        end

        it 'does add App link' do
          get '/features'
          expect(last_response.body).to match('<a.*href="/myapp"')
        end
      end

      context 'with application_href set to full url' do
        before do
          configuration.application_href = "https://myapp.com/"
        end

        it 'does add App link' do
          get '/features'
          expect(last_response.body).to match('<a.*href="https://myapp.com/"')
        end
      end
    end

    describe "feature_creation_enabled" do
      it 'sets feature_creation_enabled to true by default' do
        expect(configuration.feature_creation_enabled).to be(true)
      end

      context 'with feature_creation_enabled set to true' do
        before do
          @original_feature_creation_enabled = configuration.feature_creation_enabled
          configuration.feature_creation_enabled = true
        end

        it 'has the add_feature button' do
          get '/features'
          expect(last_response.body).to include('Add Feature')
        end

        after do
          configuration.feature_creation_enabled = @original_feature_creation_enabled
        end
      end

      context 'with feature_creation_enabled set to false' do
        before do
          @original_feature_creation_enabled = configuration.feature_creation_enabled
          configuration.feature_creation_enabled = false
        end

        it 'does not have the add_feature button' do
          get '/features'
          expect(last_response.body).not_to include('Add Feature')
        end

        after do
          configuration.feature_creation_enabled = @original_feature_creation_enabled
        end
      end
    end

    describe "feature_removal_enabled" do
      it 'sets feature_removal_enabled to true by default' do
        expect(configuration.feature_removal_enabled).to be(true)
      end

      context 'with feature_removal_enabled set to true' do
        before do
          @original_feature_removal_enabled = configuration.feature_removal_enabled
          configuration.feature_removal_enabled = true
        end

        it 'has the add_feature button' do
          get '/features/test'
          expect(last_response.body).to include('Delete')
        end

        after do
          configuration.feature_removal_enabled = @original_feature_removal_enabled
        end
      end

      context 'with feature_removal_enabled set to false' do
        before do
          @original_feature_removal_enabled = configuration.feature_removal_enabled
          configuration.feature_removal_enabled = false
        end

        it 'does not have the add_feature button' do
          get '/features/test'
          expect(last_response.body).not_to include('Delete')
        end

        after do
          configuration.feature_removal_enabled = @original_feature_removal_enabled
        end
      end
    end
  end
end
