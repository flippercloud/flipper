require "flipper/expression"

module Flipper
  module Expressions
    class Now < Expression
      def call
        ::Time.now
      end
    end
  end
end
