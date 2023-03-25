require "flipper/expression"

module Flipper
  module Expressions
    class Now < Expression
      def initialize(_ = nil)
        super []
      end

      def evaluate(context = {})
        ::Time.now
      end
    end
  end
end
