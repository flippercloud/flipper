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

    it "should not include a link back to the application" do
      expect(last_response.body).to_not include('Back to App')
    end

    context "with an app_url" do
      before do
        Flipper::UI.app_url = "/admin"
        flipper[:stats].enable
        get "/features"
      end

      it "should render a link back to the parent app" do
        expect(last_response.body).to include('<a class="btn btn-sm right" href="/admin">Back to App</a>')
      end
    end
  end

  describe "POST /features" do
    before do
      post "/features",
        {"value" => "notifications_next", "authenticity_token" => "a"},
        "rack.session" => {:csrf => "a"}
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
