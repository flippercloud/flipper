require "flipper/expression"

module Flipper
  module Expressions
    class Min
      def self.call(*args)
        args.min
      end
    end
  end
end
