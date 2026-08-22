require 'flipper/expression'

module Flipper
  module Api
    module ExpressionValidation
      VALIDATABLE_NAMES = %w[
        All
        Any
        Boolean
        Equal
        GreaterThan
        GreaterThanOrEqualTo
        LessThan
        LessThanOrEqualTo
        NotEqual
        Now
        Number
        Percentage
        PercentageOfActors
        String
        Time
      ].freeze
      private_constant :VALIDATABLE_NAMES

      def self.build(object)
        validate_shape(object)
        expression = Flipper::Expression.build(object)
        raise ArgumentError if expression.empty_groups?

        validate_arity(expression)
        validate_domains(expression)
        expression
      end

      def self.validate_shape(node)
        raise ArgumentError unless node.is_a?(Hash) && node.size == 1

        Array(node.values.first).each do |argument|
          validate_shape(argument) if argument.is_a?(Hash)
        end
      end
      private_class_method :validate_shape

      def self.validate_arity(expression)
        parameters = expression.function.method(:call).parameters
        required = parameters.count { |type, _| type == :req }
        optional = parameters.count { |type, _| type == :opt }
        has_rest = parameters.any? { |type, _| type == :rest }
        argument_count = expression.args.length

        raise ArgumentError if argument_count < required
        raise ArgumentError if !has_rest && argument_count > required + optional
        expression.args.each do |argument|
          validate_arity(argument) if argument.is_a?(Flipper::Expression)
        end
      end
      private_class_method :validate_arity

      def self.validate_domains(expression)
        if expression.is_a?(Flipper::Expression::Constant)
          return [true, expression.value]
        end

        results = expression.args.map { |argument| validate_domains(argument) }
        if expression.name == 'Random'
          if results.first && results.first.first && !results.first.last.is_a?(Numeric)
            raise ArgumentError
          end
          return [false, nil]
        end
        return [false, nil] unless VALIDATABLE_NAMES.include?(expression.name)
        return [false, nil] unless results.all?(&:first)

        values = results.map(&:last)
        parameters = expression.function.method(:call).parameters
        context = parameters.any? do |type, name|
          [:key, :keyreq].include?(type) && name == :context
        end
        value = if context
          expression.function.call(*values, context: {})
        else
          expression.function.call(*values)
        end
        [true, value]
      rescue TypeError, NoMethodError, RangeError
        raise ArgumentError
      end
      private_class_method :validate_domains
    end
  end
end
