require 'helper'

RSpec.describe Flipper::UI do
  describe "Initializing middleware with flipper instance" do
    let(:app) { build_app(flipper) }

    it "works" do
      flipper.enable :some_great_feature
      get "/features"
      expect(last_response.status).to be(200)
      expect(last_response.body).to include("some_great_feature")
    end
  end

  describe "Initializing middleware lazily with a block" do
    let(:app) {
      build_app(lambda { flipper })
    }

    it "works" do
      flipper.enable :some_great_feature
      get "/features"
      expect(last_response.status).to be(200)
      expect(last_response.body).to include("some_great_feature")
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
    expect(last_response.status).to be(302)
    expect(last_response.headers["Location"]).to eq("/features/refactor-images")
  end

  it "should not have an app_path by default" do
    expect(Flipper::UI.app_path).to be(nil)
  end

  context "with app_path not set" do
    before do
      @original_app_path = Flipper::UI.app_path
      Flipper::UI.app_path = nil
    end

    after do
      Flipper::UI.app_path = @original_app_path
    end

    it 'does not add App breadcrumb' do
      get "/features"
      expect(last_response.body).to_not include('<a href="/myapp">App</a>')
    end
  end

  context "with app_path set" do
    before do
      @original_app_path = Flipper::UI.app_path
      Flipper::UI.app_path = "/myapp"
    end

    after do
      Flipper::UI.app_path = @original_app_path
    end

    it 'does add App breadcrumb' do
      get "/features"
      expect(last_response.body).to include('<a href="/myapp">App</a>')
    end
  end

  context "with app_path set to full url" do
    before do
      @original_app_path = Flipper::UI.app_path
      Flipper::UI.app_path = "https://myapp.com/"
    end

    after do
      Flipper::UI.app_path = @original_app_path
    end

    it 'does add App breadcrumb' do
      get "/features"
      expect(last_response.body).to include('<a href="https://myapp.com/">App</a>')
    end
  end
end
