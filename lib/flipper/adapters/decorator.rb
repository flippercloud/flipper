require 'flipper/decorator'

module Flipper
  module Adapters
    # Public: Adapter super class for decorating another adapter. Used internally
    # in flipper for the instrumented, memoizable and operation logger adapters.
    class Decorator < ::Flipper::Decorator
      include Adapter
    end
  end
end
