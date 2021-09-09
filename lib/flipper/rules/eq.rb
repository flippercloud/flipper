require "flipper/rules/operator"

module Flipper
  module Rules
    class Eq < Operator
      def initialize
        super :eq
      end

      def call(left:, right:, **)
        left == right
      end
    end
  end
end
