require 'helper'
require 'flipper/ui/actor'

describe Flipper::UI::Actions::ActorsGate do
  describe "GET /features/:feature/actors" do
    before do
      get "features/search/actors"
    end

    it "responds with success" do
      last_response.status.should be(200)
    end

    it "renders add new actor form" do
      last_response.body.should include('<form action="/features/search/actors" method="post">')
    end
  end

  describe "POST /features/:feature/actors" do
    context "enabling an actor" do
      before do
        post "features/search/actors",
          {"value" => "User:6", "operation" => "enable", "authenticity_token" => "a"},
          "rack.session" => {:csrf => "a"}
      end

      it "adds item to members" do
        flipper[:search].actors_value.should include("User:6")
      end

      it "redirects back to feature" do
        last_response.status.should be(302)
        last_response.headers["Location"].should eq("/features/search")
      end
    end

    context "disabling an actor" do
      before do
        flipper[:search].enable_actor Flipper::UI::Actor.new("User:6")
        post "features/search/actors",
          {"value" => "User:6", "operation" => "disable", "authenticity_token" => "a"},
          "rack.session" => {:csrf => "a"}
      end

      it "removes item from members" do
        flipper[:search].actors_value.should_not include("User:6")
      end

      it "redirects back to feature" do
        last_response.status.should be(302)
        last_response.headers["Location"].should eq("/features/search")
      end
    end

    context "for an invalid actor value" do
      before do
        post "features/search/actors",
          {"value" => "", "operation" => "enable", "authenticity_token" => "a"},
          "rack.session" => {:csrf => "a"}
      end

      it "redirects back to feature" do
        last_response.status.should be(302)
        last_response.headers["Location"].should eq("/features/search/actors?error=%22%22+is+not+a+valid+actor+value.")
      end
    end
  end
end
