require 'helper'

describe Flipper::UI::Actions::Gate do
  describe "POST /features/:feature/non-existent-gate" do
    before do
      post "/features/search/non-existent-gate",
        {"authenticity_token" => "a"},
        "rack.session" => {:csrf => "a"}
    end

    it "responds with redirect" do
      last_response.status.should be(302)
    end

    it "escapes error message" do
      last_response.headers["Location"].should eq("/features/search?error=%22non-existent-gate%22+gate+does+not+exist+therefore+it+cannot+be+updated.")
    end

    it "renders error in template" do
      follow_redirect!
      last_response.body.should match(/non-existent-gate.*gate does not exist/)
    end
  end
end
