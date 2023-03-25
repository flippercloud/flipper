require "flipper/expression"

module Flipper
  module Expressions
    class Equal < Comparable
      def operator
        :==
      end
    end
  end
end
