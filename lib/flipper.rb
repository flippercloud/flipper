require 'flipper/configuration'
require 'flipper/feature'

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

end
