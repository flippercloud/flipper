require "flipper/rules/operator"

module Flipper
  module Rules
    class Lte < Operator
      def initialize
        super :lte
      end

      def call(left:, right:, **)
        left && right && left <= right
      end
    end
  end
end
