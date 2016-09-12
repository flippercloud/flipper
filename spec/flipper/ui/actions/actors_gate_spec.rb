require 'helper'

RSpec.describe Flipper::UI::Actions::ActorsGate do
  let(:token) {
    if Rack::Protection::AuthenticityToken.respond_to?(:random_token)
      Rack::Protection::AuthenticityToken.random_token
    else
      "a"
    end
  }
  let(:session) {
    if Rack::Protection::AuthenticityToken.respond_to?(:random_token)
      {:csrf => token}
    else
      {"_csrf_token" => token}
    end
  }

  describe "GET /features/:feature/actors" do
    before do
      get "features/search/actors"
    end

    it "responds with success" do
      expect(last_response.status).to be(200)
    end

    it "renders add new actor form" do
      expect(last_response.body).to include('<form action="/features/search/actors" method="post">')
    end
  end

  describe "POST /features/:feature/actors" do
    context "enabling an actor" do
      before do
        post "features/search/actors",
          {"value" => "User:6", "operation" => "enable", "authenticity_token" => token},
          "rack.session" => session
      end

      it "adds item to members" do
        expect(flipper[:search].actors_value).to include("User:6")
      end

      it "redirects back to feature" do
        expect(last_response.status).to be(302)
        expect(last_response.headers["Location"]).to eq("/features/search")
      end
    end

    context "disabling an actor" do
      before do
        flipper[:search].enable_actor Flipper::UI::Actor.new("User:6")
        post "features/search/actors",
          {"value" => "User:6", "operation" => "disable", "authenticity_token" => token},
          "rack.session" => session
      end

      it "removes item from members" do
        expect(flipper[:search].actors_value).not_to include("User:6")
      end

      it "redirects back to feature" do
        expect(last_response.status).to be(302)
        expect(last_response.headers["Location"]).to eq("/features/search")
      end
    end

    context "for an invalid actor value" do
      before do
        post "features/search/actors",
          {"value" => "", "operation" => "enable", "authenticity_token" => token},
          "rack.session" => session
      end

      it "redirects back to feature" do
        expect(last_response.status).to be(302)
        expect(last_response.headers["Location"]).to eq("/features/search/actors?error=%22%22+is+not+a+valid+actor+value.")
      end
    end
  end
end
