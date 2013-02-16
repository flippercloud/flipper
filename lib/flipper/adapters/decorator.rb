require 'flipper/decorator'

module Flipper
  module Adapters
    class Decorator < ::Flipper::Decorator
      include Flipper::Adapter
    end
  end
end
