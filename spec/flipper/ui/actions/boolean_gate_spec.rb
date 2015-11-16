require 'helper'

RSpec.describe Flipper::UI::Actions::BooleanGate do
  describe "POST /features/:feature/boolean" do
    context "with enable" do
      before do
        flipper.disable :search
        post "features/search/boolean",
          {"action" => "Enable", "authenticity_token" => "a"},
          "rack.session" => {:csrf => "a"}
      end

      it "enables the feature" do
        expect(flipper.enabled?(:search)).to be(true)
      end

      it "redirects back to feature" do
        expect(last_response.status).to be(302)
        expect(last_response.headers["Location"]).to eq("/features/search")
      end
    end

    context "with disable" do
      before do
        flipper.enable :search
        post "features/search/boolean",
          {"action" => "Disable", "authenticity_token" => "a"},
          "rack.session" => {:csrf => "a"}
      end

      it "disables the feature" do
        expect(flipper.enabled?(:search)).to be(false)
      end

      it "redirects back to feature" do
        expect(last_response.status).to be(302)
        expect(last_response.headers["Location"]).to eq("/features/search")
      end
    end
  end
end
