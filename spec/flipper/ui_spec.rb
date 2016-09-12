require 'helper'

RSpec.describe Flipper::UI do
  let(:token) {
    if Rack::Protection::AuthenticityToken.respond_to?(:random_token)
      Rack::Protection::AuthenticityToken.random_token
    else
      "a"
    end
  }
  let(:session) {
    if Rack::Protection::AuthenticityToken.respond_to?(:random_token)
      {:csrf => token}
    else
      {"_csrf_token" => token}
    end
  }

  describe "Initializing middleware with flipper instance" do
    let(:app) { build_app(flipper) }

    it "works" do
      flipper.enable :some_great_feature
      get "/features"
      expect(last_response.status).to be(200)
      expect(last_response.body).to include("some_great_feature")
    end
  end

  describe "Initializing middleware lazily with a block" do
    let(:app) {
      build_app(lambda { flipper })
    }

    it "works" do
      flipper.enable :some_great_feature
      get "/features"
      expect(last_response.status).to be(200)
      expect(last_response.body).to include("some_great_feature")
    end
  end

  describe "Request method unsupported by action" do
    it "raises error" do
      expect {
        head '/features'
      }.to raise_error(Flipper::UI::RequestMethodNotSupported)
    end
  end

  # See https://github.com/jnunemaker/flipper/issues/80
  it "can route features with names that match static directories" do
    post "features/refactor-images/actors",
      {"value" => "User:6", "operation" => "enable", "authenticity_token" => token},
      "rack.session" => session
    expect(last_response.status).to be(302)
    expect(last_response.headers["Location"]).to eq("/features/refactor-images")
  end

  it "should not have an application_breadcrumb_href by default" do
    expect(Flipper::UI.application_breadcrumb_href).to be(nil)
  end

  context "with application_breadcrumb_href not set" do
    before do
      @original_application_breadcrumb_href = Flipper::UI.application_breadcrumb_href
      Flipper::UI.application_breadcrumb_href = nil
    end

    after do
      Flipper::UI.application_breadcrumb_href = @original_application_breadcrumb_href
    end

    it 'does not add App breadcrumb' do
      get "/features"
      expect(last_response.body).to_not include('<a href="/myapp">App</a>')
    end
  end

  context "with application_breadcrumb_href set" do
    before do
      @original_application_breadcrumb_href = Flipper::UI.application_breadcrumb_href
      Flipper::UI.application_breadcrumb_href = "/myapp"
    end

    after do
      Flipper::UI.application_breadcrumb_href = @original_application_breadcrumb_href
    end

    it 'does add App breadcrumb' do
      get "/features"
      expect(last_response.body).to include('<a href="/myapp">App</a>')
    end
  end

  context "with application_breadcrumb_href set to full url" do
    before do
      @original_application_breadcrumb_href = Flipper::UI.application_breadcrumb_href
      Flipper::UI.application_breadcrumb_href = "https://myapp.com/"
    end

    after do
      Flipper::UI.application_breadcrumb_href = @original_application_breadcrumb_href
    end

    it 'does add App breadcrumb' do
      get "/features"
      expect(last_response.body).to include('<a href="https://myapp.com/">App</a>')
    end
  end

  it "should set feature_creation_enabled to true by default" do
    expect(Flipper::UI.feature_creation_enabled).to be(true)
  end

  context "with feature_creation_enabled set to true" do
    before do
      @original_feature_creation_enabled = Flipper::UI.feature_creation_enabled
      Flipper::UI.feature_creation_enabled = true
    end

    it 'has the add_feature button' do
      get '/features'
      expect(last_response.body).to include('Add Feature')
    end

    after do
      Flipper::UI.feature_creation_enabled = @original_feature_creation_enabled
    end
  end

  context "with feature_creation_enabled set to false" do
    before do
      @original_feature_creation_enabled = Flipper::UI.feature_creation_enabled
      Flipper::UI.feature_creation_enabled = false
    end

    it 'does not have the add_feature button' do
      get '/features'
      expect(last_response.body).to_not include('Add Feature')
    end

    after do
      Flipper::UI.feature_creation_enabled = @original_feature_creation_enabled
    end
  end

end
