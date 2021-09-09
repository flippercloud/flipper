require "flipper/rules/operator"

module Flipper
  module Rules
    class Gt < Operator
      def initialize
        super :gt
      end

      def call(left:, right:, **)
        left && right && left > right
      end
    end
  end
end
