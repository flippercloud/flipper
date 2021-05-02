require 'helper'
require 'rails'
require 'flipper/cloud'

RSpec.describe Flipper::Cloud::Engine do
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
    expect(Flipper.instance).to be_a(Flipper::Cloud::DSL)
  end

  it "configures webhook app" do
    with_modified_env "FLIPPER_CLOUD_SYNC_SECRET" => "abc" do
      application.initialize!

      # TOOD: test this…
    end
  end
end
