module Flipper
  module Rules
    class Operator

      OPERATIONS = {
        "eq"  => -> (left:, right:, **) { left == right },
        "neq" => -> (left:, right:, **) { left != right },
        "gt"  => -> (left:, right:, **) { left && right && left > right },
        "gte" => -> (left:, right:, **) { left && right && left >= right },
        "lt"  => -> (left:, right:, **) { left && right && left < right },
        "lte" => -> (left:, right:, **) { left && right && left <= right },
        "in"  => -> (left:, right:, **) { left && right && right.include?(left) },
        "nin" => -> (left:, right:, **) { left && right && !right.include?(left) },
        "percentage" => -> (left:, right:, feature_name:) do
          # this is to support up to 3 decimal places in percentages
          scaling_factor = 1_000
          id = "#{feature_name}#{left}"
          left && right && (Zlib.crc32(id) % (100 * scaling_factor) < right * scaling_factor)
        end
      }.freeze

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
        @block = OPERATIONS.fetch(@value) {
          raise ArgumentError, "Operator '#{@value}' could not be found"
        }
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

      def call(*args)
        @block.call(*args)
      end
    end
  end
end
