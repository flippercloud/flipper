require 'helper'

describe Flipper::UI::Actions::Feature do
  describe "DELETE /features/:feature" do
    before do
      flipper.enable :search
      delete "/features/search",
        {"authenticity_token" => "a"},
        "rack.session" => {:csrf => "a"}
    end

    it "removes feature" do
      flipper.features.map(&:key).should_not include("search")
    end

    it "redirects to features" do
      last_response.status.should be(302)
      last_response.headers["Location"].should eq("/features")
    end
  end

  describe "POST /features/:feature with _method=DELETE" do
    before do
      flipper.enable :search
      post "/features/search",
        {"_method" => "DELETE", "authenticity_token" => "a"},
        "rack.session" => {:csrf => "a"}
    end

    it "removes feature" do
      flipper.features.map(&:key).should_not include("search")
    end

    it "redirects to features" do
      last_response.status.should be(302)
      last_response.headers["Location"].should eq("/features")
    end
  end

  describe "GET /features/:feature" do
    before do
      get "/features/search"
    end

    it "responds with success" do
      last_response.status.should be(200)
    end

    it "renders template" do
      last_response.body.should include("search")
      last_response.body.should include("Enable")
      last_response.body.should include("Disable")
      last_response.body.should include("Actors")
      last_response.body.should include("Groups")
      last_response.body.should include("Percentage of Time")
      last_response.body.should include("Percentage of Actors")
    end
  end
end
