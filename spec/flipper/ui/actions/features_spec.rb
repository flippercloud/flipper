require 'helper'

describe Flipper::UI::Actions::Features do
  describe "GET /features" do
    before do
      flipper[:stats].enable
      flipper[:search].enable
      get "/features"
    end

    it "responds with success" do
      last_response.status.should be(200)
    end

    it "renders template" do
      last_response.body.should include("stats")
      last_response.body.should include("search")
    end
  end

  describe "POST /features" do
    before do
      post "/features",
        {"value" => "notifications_next", "authenticity_token" => "a"},
        "rack.session" => {:csrf => "a"}
    end

    it "adds feature" do
      flipper.features.map(&:key).should include("notifications_next")
    end

    it "redirects to feature" do
      last_response.status.should be(302)
      last_response.headers["Location"].should eq("/features/notifications_next")
    end
  end
end
