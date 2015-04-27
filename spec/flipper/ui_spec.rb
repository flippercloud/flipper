require 'helper'
require 'rack/test'
require 'flipper'
require 'flipper/adapters/memory'

describe Flipper::UI do
  include Rack::Test::Methods

  let(:flipper) { build_flipper }
  let(:app)     { build_app(flipper) }

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
    let(:app) { Flipper::UI.app(lambda { flipper }, secret: "test") }

    it "works" do
      flipper.enable :some_great_feature
      get "/features"
      last_response.status.should be(200)
      last_response.body.should include("some_great_feature")
    end
  end

  describe "Creating app without secret" do
    it "raises argument error" do
      expect { Flipper::UI.app(flipper) }.to raise_error(ArgumentError, "Flipper::UI.app missing required option: secret")
    end
  end

  describe "Request method unsupported by action" do
    it "raises error" do
      expect {
        head '/features'
      }.to raise_error(Flipper::UI::RequestMethodNotSupported)
    end
  end
end
