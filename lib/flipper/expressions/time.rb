require "flipper/expression"

module Flipper
  module Expressions
    class Time < Expression
      def call(value)
        ::Time.parse(value)
      end
    end
  end
end
