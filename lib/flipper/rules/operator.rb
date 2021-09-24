module Flipper
  module Rules
    module Operator
      # Builds a flipper operator based on an object.
      #
      # object - The Hash, String, Symbol or Flipper::Rules::Operators::*
      # representation of an operator.
      #
      # Returns Flipper::Rules::Operator::* instance.
      def self.build(object)
        return object if object.is_a?(Flipper::Rules::Operators::Base)

        operator_class = case object
        when Hash
          object.fetch("value")
        when String, Symbol
          object
        else
          raise ArgumentError, "#{object.inspect} cannot be converted into an operator"
        end

        Operators.const_get(operator_class.to_s.capitalize).new
      end
    end
  end
end

require "flipper/rules/operators/eq"
require "flipper/rules/operators/neq"
require "flipper/rules/operators/gt"
require "flipper/rules/operators/gte"
require "flipper/rules/operators/lt"
require "flipper/rules/operators/lte"
require "flipper/rules/operators/percentage"
