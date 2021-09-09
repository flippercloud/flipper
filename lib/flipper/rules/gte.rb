require "flipper/rules/operator"

module Flipper
  module Rules
    class Gte < Operator
      def initialize
        super :gte
      end

      def call(left:, right:, **)
        left && right && left >= right
      end
    end
  end
end
