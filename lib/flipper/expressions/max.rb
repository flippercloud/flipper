require "flipper/expression"

module Flipper
  module Expressions
    class Max
      def self.call(*args)
        args.max
      end
    end
  end
end
