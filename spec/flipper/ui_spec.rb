require 'helper'

describe Flipper::UI do
  describe "Initializing middleware with flipper instance" do
    let(:app) { build_app(flipper) }

    it "works" do
      flipper.enable :some_great_feature
      get "/features"
      last_response.status.should be(200)
      last_response.body.should include("some_great_feature")
    end
  end

  describe "Initializing middleware lazily with a block" do
    let(:app) {
      build_app(lambda { flipper })
    }

    it "works" do
      flipper.enable :some_great_feature
      get "/features"
      last_response.status.should be(200)
      last_response.body.should include("some_great_feature")
    end
  end

  describe "Request method unsupported by action" do
    it "raises error" do
      expect {
        head '/features'
      }.to raise_error(Flipper::UI::RequestMethodNotSupported)
    end
  end

  # See https://github.com/jnunemaker/flipper/issues/80
  it "can route features with names that match static directories" do
    post "features/refactor-images/actors",
      {"value" => "User:6", "operation" => "enable", "authenticity_token" => "a"},
      "rack.session" => {:csrf => "a"}
    last_response.status.should be(302)
    last_response.headers["Location"].should eq("/features/refactor-images")
  end
end
