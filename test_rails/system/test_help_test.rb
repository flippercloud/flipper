require_relative "../helper"
require "capybara/cuprite"
require "flipper"
require "flipper/test_help"

require 'action_dispatch/system_testing/server'
ActionDispatch::SystemTesting::Server.silence_puma = true

class TestApp < Rails::Application
  config.eager_load = false
  config.logger = ActiveSupport::Logger.new(StringIO.new)
  config.active_support.cache_format_version = 7.1
  routes.append do
    root to: "features#index"
  end
end

TestApp.initialize!

class FeaturesController < ActionController::Base
  def index
    render inline: Flipper.enabled?(:test) ? "Enabled" : "Disabled"
  end
end

class TestHelpTest < ActionDispatch::SystemTestCase
  # Any driver that runs the app in a separate thread will test what we want here.
  driven_by :cuprite

  test "configures a shared adapter between tests and app" do
    Flipper.disable(:test)
    visit "/"
    assert_selector "*", text: "Disabled"

    Flipper.enable(:test)
    visit "/"
    assert_selector "*", text: "Enabled"
  end
end
