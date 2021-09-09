require "flipper/rules/operator"

module Flipper
  module Rules
    class Lt < Operator
      def initialize
        super :lt
      end

      def call(left:, right:, **)
        left && right && left < right
      end
    end
  end
end
