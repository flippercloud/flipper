require 'helper'

describe Flipper::UI::Actions::AddFeature do
  describe "GET /features/new" do
    before do
      get "/features/new"
    end

    it "responds with success" do
      last_response.status.should be(200)
    end

    it "renders template" do
      last_response.body.should include('<form action="/features" method="post">')
    end
  end
end
