require 'helper'

describe Flipper::UI::Actions::BooleanGate do
  describe "POST /features/:feature/boolean" do
    context "with enable" do
      before do
        flipper.disable :search
        post "features/search/boolean",
          {"action" => "Enable", "authenticity_token" => "a"},
          "rack.session" => {:csrf => "a"}
      end

      it "enables the feature" do
        flipper.enabled?(:search).should be(true)
      end

      it "redirects back to feature" do
        last_response.status.should be(302)
        last_response.headers["Location"].should eq("/features/search")
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
        flipper.enabled?(:search).should be(false)
      end

      it "redirects back to feature" do
        last_response.status.should be(302)
        last_response.headers["Location"].should eq("/features/search")
      end
    end
  end
end
