require 'flipper/rules/rule'

module Flipper
  module Rules
    class Condition < Rule
      def self.build(hash)
        new(hash.fetch("left"), hash.fetch("operator"), hash.fetch("right"))
      end

      attr_reader :left, :operator, :right

      def initialize(left, operator, right)
        @left = left
        @operator = Operator.wrap(operator)
        @right = right
      end

      def value
        {
          "type" => "Condition",
          "value" => {
            "left" => @left,
            "operator" => @operator.to_h,
            "right" => @right,
          }
        }
      end

      def eql?(other)
        self.class.eql?(other.class) &&
          @left == other.left &&
          @operator == other.operator &&
          @right == other.right
      end
      alias_method :==, :eql?

      def matches?(feature_name, actor = nil)
        properties = actor ? actor.flipper_properties.merge("flipper_id" => actor.flipper_id) : {}.freeze
        left_value = evaluate(@left, properties)
        right_value = evaluate(@right, properties)
        !!@operator.call(left: left_value, right: right_value, feature_name: feature_name)
      end

      private

      def evaluate(hash, properties)
        type = hash.fetch("type")

        case type
        when "Property"
          properties[hash.fetch("value")]
        when "Random"
          rand hash.fetch("value")
        when "Array", "String", "Integer", "Boolean"
          hash.fetch("value")
        when "Null"
          nil
        else
          raise "type not found: #{type.inspect}"
        end
      end
    end
  end
end
