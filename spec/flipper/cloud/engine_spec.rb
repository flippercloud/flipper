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

    # Force loading of flipper to configure itself
    load 'flipper-cloud.rb'
  end

  it "initializes cloud configuration" do
    expect(Flipper.configuration).to be_a(Flipper::Cloud::Configuration)
    expect(Flipper.instance).to be_a(Flipper::Cloud::DSL)
  end

  it "configures webhook app" do
    Flipper.configuration.sync_secret = 'abc'
    Flipper.configuration.sync_method = :webhook

    application.initialize!

    # TOOD: test this…
  end
end
