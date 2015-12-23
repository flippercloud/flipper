require 'helper'

RSpec.describe Flipper::UI::Actions::Features do
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

  describe "POST /features" do
    before do
      post "/features",
        {"value" => "notifications_next", "authenticity_token" => "a"},
        "rack.session" => {"_csrf_token" => "a"}
    end

    it "adds feature" do
      expect(flipper.features.map(&:key)).to include("notifications_next")
    end

    it "redirects to feature" do
      expect(last_response.status).to be(302)
      expect(last_response.headers["Location"]).to eq("/features/notifications_next")
    end
  end
end
