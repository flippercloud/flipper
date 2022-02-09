require "flipper/expression"

module Flipper
  module Expressions
    class Percentage < Number
      def initialize(args)
        super Array(args)
      end

      def evaluate(context = {})
        value = super

        value = 0 if value < 0
        value = 100 if value > 100

        value
      end
    end
  end
end
