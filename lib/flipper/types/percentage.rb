module Flipper
  module Types
    class Percentage < Type
      attr_reader :value

      def initialize(value)
        @value = value.to_i
      end

      def eql?(other)
        self.class.eql?(other.class) && value == other.value
      end
      alias :== :eql?
    end
  end
end
