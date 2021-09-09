require "flipper/rules/operator"

module Flipper
  module Rules
    class In < Operator
      def initialize
        super :in
      end

      def call(left:, right:, **)
        left && right && right.include?(left)
      end
    end
  end
end
