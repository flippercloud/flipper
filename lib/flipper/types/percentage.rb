module Flipper
  module Types
    class Percentage < Type
      attr_reader :value

      def initialize(value)
        @value = value.to_i
      end

      def enabled_value
        value
      end

      def disabled_value
        0
      end
    end
  end
end
