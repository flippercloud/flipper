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
end
