module Flipper
  module Rules
    class Operator
      attr_reader :type, :value

      # Ensures object is an Flipper::Rules::Operator..
      #
      # object - The Hash or Flipper::Rules::Operator. instance.
      #
      # Returns Flipper::Rules::Operator.
      # Raises Flipper::Errors::OperatorNotFound if not a known operator.
      def self.wrap(object)
        return object if object.is_a?(Flipper::Rules::Operator)

        new(object.fetch("value"))
      end

      def initialize(value)
        @type = "Operator".freeze
        @value = value.to_s

        unless Condition::OPERATIONS.key?(@value)
          raise ArgumentError, "Operator '#{@value}' could not be found"
        end
      end

      def name
        @value
      end

      def to_h
        {
          "type" => @type,
          "value" => @value,
        }
      end

      def eql?(other)
        self.class.eql?(other.class) &&
          @type == other.type &&
          @value == other.value
      end
      alias_method :==, :eql?
    end
  end
end
