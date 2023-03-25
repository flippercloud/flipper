require "flipper/expression"

module Flipper
  module Expressions
    class NotEqual < Comparable
      def operator
        :!=
      end
    end
  end
end
