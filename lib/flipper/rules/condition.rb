module Flipper
  module Rules
    class Condition
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
      }

      def self.build(hash)
        new(hash.fetch("left"), hash.fetch("operator"), hash.fetch("right"))
      end

      def initialize(left, operator, right)
        @left = left
        @operator = operator
        @right = right
      end

      def value
        {
          "type" => "Condition",
          "value" => {
            "left" => @left,
            "operator" => @operator,
            "right" => @right,
          }
        }
      end

      def matches?(feature_name, actor)
        attributes = actor.flipper_properties
        left_value = evaluate(@left, attributes)
        right_value = evaluate(@right, attributes)
        operator_name = @operator.fetch("value")
        operation = OPERATIONS.fetch(operator_name) do
          raise "operator not implemented: #{operator_name}"
        end

        !!operation.call(left: left_value, right: right_value, feature_name: feature_name)
      end

      private

      def evaluate(hash, attributes)
        type = hash.fetch("type")

        case type
        when "property"
          attributes[hash.fetch("value")]
        when "array"
          hash.fetch("value")
        when "string"
          hash.fetch("value")
        when "random"
          rand hash.fetch("value")
        when "integer"
          hash.fetch("value")
        else
          raise "type not found: #{type.inspect}"
        end
      end
    end
  end
end
