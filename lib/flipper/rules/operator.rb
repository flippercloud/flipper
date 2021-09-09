module Flipper
  module Rules
    class Operator
      attr_reader :type, :value

      # Builds a Flipper::Rules::Operator based on an object.
      #
      # object - The Hash, String, Symbol or Flipper::Rules::Operator
      # representation of an operator.
      #
      # Returns Flipper::Rules::Operator.
      # Raises Flipper::Errors::OperatorNotFound if not a known operator.
      def self.build(object)
        return object if object.is_a?(Flipper::Rules::Operator)

        operator_class = case object
        when Hash
          object.fetch("value")
        when String, Symbol
          object
        else
          raise ArgumentError, "#{object.inspect} cannot be converted into an operator"
        end

        Rules.const_get(operator_class.to_s.capitalize).new
      end

      def initialize(value)
        @type = "Operator".freeze
        @value = value.to_s
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
        raise NotImplementedError
      end
    end
  end
end

require "flipper/rules/eq"
require "flipper/rules/neq"
require "flipper/rules/gt"
require "flipper/rules/gte"
require "flipper/rules/lt"
require "flipper/rules/lte"
require "flipper/rules/in"
require "flipper/rules/nin"
require "flipper/rules/percentage"
