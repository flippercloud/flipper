module Flipper
  module Types
    class Percentage < Type
      attr_reader :value

      def initialize(value)
        @value = value.to_i
      end
    end
  end
end
