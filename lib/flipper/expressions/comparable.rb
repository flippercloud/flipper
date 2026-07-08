module Flipper
  module Expressions
    class Comparable
      def self.operator
        raise NotImplementedError
      end

      def self.call(left, right)
        left.respond_to?(operator) && right.respond_to?(operator) && left.public_send(operator, right)
      rescue ArgumentError
        # Operands respond to the operator but aren't type-compatible
        # (e.g. "25" > 21), which raises ArgumentError. Treat as false.
        false
      end
    end
  end
end
