require "flipper/rules/operator"

module Flipper
  module Rules
    class Neq < Operator
      def initialize
        super :neq
      end

      def call(left:, right:, **)
        left != right
      end
    end
  end
end
