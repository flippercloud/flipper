require 'helper'

RSpec.describe Flipper::UI::Actions::AddFeature do
  describe "GET /features/new" do
    before do
      get "/features/new"
    end

    it "responds with success" do
      expect(last_response.status).to be(200)
    end

    it "renders template" do
      expect(last_response.body).to include('<form action="/features" method="post">')
    end
  end
end
