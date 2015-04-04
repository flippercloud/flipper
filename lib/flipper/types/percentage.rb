module Flipper
  module Types
    class Percentage < Type

      def self.wrap(value)
        return value if value.is_a?(self)
        new(value)
      end

      attr_reader :value

      def initialize(value)
        value = Typecast.to_integer(value)

        if value < 0 || value > 100
          raise ArgumentError, "value must be a positive number less than or equal to 100, but was #{value}"
        end

        @value = value
      end

      def eql?(other)
        self.class.eql?(other.class) && value == other.value
      end
      alias_method :==, :eql?
    end
  end
end
