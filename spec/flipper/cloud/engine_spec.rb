require 'helper'
require 'rails'
require 'flipper/cloud'

RSpec.describe Flipper::Cloud::Engine do
  let(:env) do
    {
      "FLIPPER_CLOUD_TOKEN" => "ASDF",
      "FLIPPER_CLOUD_SYNC_SECRET" => "abc"
    }
  end

  let(:application) do
    Class.new(Rails::Application) do
      config.eager_load = false
      config.logger = ActiveSupport::Logger.new($stdout)
    end
  end

  before do
    Rails.application = nil

    stub_request(:get, /flippercloud\.io/).to_return(status: 200, body: "{}")

    # Force loading of flipper to configure itself
    load 'flipper-cloud.rb'
  end

  it "initializes cloud configuration" do
    with_modified_env env do
      expect(Flipper.instance).to be_a(Flipper::Cloud::DSL)
    end
  end

  it "configures webhook app" do
    with_modified_env env do
      application.initialize!

      # TOOD: test this…
    end
  end
end
