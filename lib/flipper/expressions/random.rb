require "flipper/expression"

module Flipper
  module Expressions
    class Random < Expression
      def call(max = 0)
        rand max
      end
    end
  end
end
