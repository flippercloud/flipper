require "flipper/rules/operator"

module Flipper
  module Rules
    class Nin < Operator
      def initialize
        super :nin
      end

      def call(left:, right:, **)
        left && right && !right.include?(left)
      end
    end
  end
end
