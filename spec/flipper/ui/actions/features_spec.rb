require 'helper'

RSpec.describe Flipper::UI::Actions::Features do
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

  describe "GET /features" do
    before do
      flipper[:stats].enable
      flipper[:search].enable
      get "/features"
    end

    it "responds with success" do
      expect(last_response.status).to be(200)
    end

    it "renders template" do
      expect(last_response.body).to include("stats")
      expect(last_response.body).to include("search")
    end
  end

  describe "POST /features with feature_creation_enabled set to true" do
    before do
      @original_feature_creation_enabled = Flipper::UI.feature_creation_enabled
      Flipper::UI.feature_creation_enabled = true
      post "/features",
        {"value" => "notifications_next", "authenticity_token" => token},
        "rack.session" => session
    end

    after do
      Flipper::UI.feature_creation_enabled = @original_feature_creation_enabled
    end

    it "adds feature" do
      expect(flipper.features.map(&:key)).to include("notifications_next")
    end

    it "redirects to feature" do
      expect(last_response.status).to be(302)
      expect(last_response.headers["Location"]).to eq("/features/notifications_next")
    end
  end

  describe "POST /features with feature_creation_enabled set to false" do
    before do
      @original_feature_creation_enabled = Flipper::UI.feature_creation_enabled
      Flipper::UI.feature_creation_enabled = false
      post "/features",
        {"value" => "notifications_next", "authenticity_token" => token},
        "rack.session" => session
    end

    after do
      Flipper::UI.feature_creation_enabled = @original_feature_creation_enabled
    end

    it "does not add feature" do
      expect(flipper.features.map(&:key)).to_not include("notifications_next")
    end

    it "returns 403" do
      expect(last_response.status).to be(403)
    end

    it "renders feature creation disabled template" do
      expect(last_response.body).to include("Feature creation is disabled.")
    end
  end
end
