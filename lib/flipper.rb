require 'flipper/configuration'
require 'flipper/feature'
require 'flipper/adapters/memory'

module Flipper
  module_function

  def configuration
    @configuration ||= Configuration.new
  end

  def configuration=(configuration)
    @configuration = configuration
  end

  def configure(&block)
    block.call(configuration)
  end
end

Flipper.configure do |config|
  config.adapter = Flipper::Adapters::Memory.new
end
