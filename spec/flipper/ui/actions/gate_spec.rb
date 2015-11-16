require 'helper'

RSpec.describe Flipper::UI::Actions::Gate do
  describe "POST /features/:feature/non-existent-gate" do
    before do
      post "/features/search/non-existent-gate",
        {"authenticity_token" => "a"},
        "rack.session" => {:csrf => "a"}
    end

    it "responds with redirect" do
      expect(last_response.status).to be(302)
    end

    it "escapes error message" do
      expect(last_response.headers["Location"]).to eq("/features/search?error=%22non-existent-gate%22+gate+does+not+exist+therefore+it+cannot+be+updated.")
    end

    it "renders error in template" do
      follow_redirect!
      expect(last_response.body).to match(/non-existent-gate.*gate does not exist/)
    end
  end
end
