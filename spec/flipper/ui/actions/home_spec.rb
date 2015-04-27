require 'helper'

describe Flipper::UI::Actions::Home do
  describe "GET /" do
    before do
      flipper[:stats].enable
      flipper[:search].enable
      get "/"
    end

    it "responds with redirect" do
      last_response.status.should be(302)
      last_response.headers["Location"].should eq("/features")
    end
  end
end
