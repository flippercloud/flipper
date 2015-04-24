require 'flipper/decorator'

module Flipper
  module Adapters
    class Decorator < ::Flipper::Decorator
      include Adapter
    end
  end
end
