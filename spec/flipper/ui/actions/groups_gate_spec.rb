require 'helper'

RSpec.describe Flipper::UI::Actions::GroupsGate do
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

  describe "GET /features/:feature/groups" do
    before do
      Flipper.register(:admins) { |user| user.admin? }
      get "features/search/groups"
    end

    after do
      Flipper.unregister_groups
    end

    it "responds with success" do
      expect(last_response.status).to be(200)
    end

    it "renders add new group form" do
      expect(last_response.body).to include('<form action="/features/search/groups" method="post">')
    end
  end

  describe "POST /features/:feature/groups" do
    before do
      Flipper.register(:admins) { |user| user.admin? }
    end

    after do
      Flipper.unregister_groups
    end

    context "enabling a group" do
      before do
        post "features/search/groups",
          {"value" => "admins", "operation" => "enable", "authenticity_token" => token},
          "rack.session" => session
      end

      it "adds item to members" do
        expect(flipper[:search].groups_value).to include("admins")
      end

      it "redirects back to feature" do
        expect(last_response.status).to be(302)
        expect(last_response.headers["Location"]).to eq("/features/search")
      end
    end

    context "disabling a group" do
      before do
        flipper[:search].enable_group :admins
        post "features/search/groups",
          {"value" => "admins", "operation" => "disable", "authenticity_token" => token},
          "rack.session" => session
      end

      it "removes item from members" do
        expect(flipper[:search].groups_value).not_to include("admins")
      end

      it "redirects back to feature" do
        expect(last_response.status).to be(302)
        expect(last_response.headers["Location"]).to eq("/features/search")
      end
    end

    context "for an unregistered group" do
      before do
        post "features/search/groups",
          {"value" => "not_here", "operation" => "enable", "authenticity_token" => token},
          "rack.session" => session
      end

      it "redirects back to feature" do
        expect(last_response.status).to be(302)
        expect(last_response.headers["Location"]).to eq("/features/search/groups?error=The+group+named+%22not_here%22+has+not+been+registered.")
      end
    end
  end
end
