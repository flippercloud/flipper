require "flipper/expression"

module Flipper
  module Expressions
    class Percentage < Expression
      def call(value)
        value.to_f.clamp(0, 100)
      end
    end
  end
end
