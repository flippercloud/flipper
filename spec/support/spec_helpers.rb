require 'json'
require 'flipper/adapters/memory'
require 'rack/test'

module SpecHelpers
  def self.included(base)
    base.let(:flipper) { build_flipper }
    base.let(:app) { build_app(flipper) }
  end

  def build_app(flipper)
    Flipper::UI.app(flipper) { |builder|
      builder.use Rack::Session::Cookie
    }
  end

  def build_flipper(adapter = build_memory_adapter)
    Flipper.new(adapter)
  end

  def build_memory_adapter
    Flipper::Adapters::Memory.new
  end

  def json_response
    JSON.load(last_response.body)
  end
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include SpecHelpers
end
