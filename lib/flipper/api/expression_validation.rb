require 'flipper/expression'
require 'flipper/types/percentage'

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
      OUTPUT_DOMAINS = {
        'All' => :boolean,
        'Any' => :boolean,
        'Boolean' => :boolean,
        'Equal' => :boolean,
        'FeatureEnabled' => :boolean,
        'GreaterThan' => :boolean,
        'GreaterThanOrEqualTo' => :boolean,
        'LessThan' => :boolean,
        'LessThanOrEqualTo' => :boolean,
        'NotEqual' => :boolean,
        'Now' => :time,
        'Number' => :numeric,
        'Percentage' => :numeric,
        'PercentageOfActors' => :boolean,
        'Random' => :numeric,
        'String' => :string,
        'Time' => :time,
      }.freeze
      ValidationResult = Struct.new(:known, :value, :domain)
      private_constant :VALIDATABLE_NAMES
      private_constant :OUTPUT_DOMAINS
      private_constant :ValidationResult

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
          value = expression.value
          validate_finite_number(value)

          return ValidationResult.new(true, value, value_domain(value))
        end

        results = expression.args.map { |argument| validate_domains(argument) }
        validate_input_domains(expression.name, results)
        if expression.name == 'Random'
          maximum = results.first
          if maximum
            invalid_domain = maximum.domain && maximum.domain != :numeric
            invalid_value = maximum.known && !maximum.value.is_a?(Numeric)
            raise ArgumentError if invalid_domain || invalid_value
          end
          return ValidationResult.new(false, nil, :numeric)
        end
        if expression.name == 'PercentageOfActors'
          validate_percentage(results[1])
          return ValidationResult.new(false, nil, :boolean)
        end
        domain = OUTPUT_DOMAINS[expression.name]
        return ValidationResult.new(false, nil, domain) unless VALIDATABLE_NAMES.include?(expression.name)
        return ValidationResult.new(false, nil, domain) unless results.all?(&:known)

        values = results.map(&:value)
        parameters = expression.function.method(:call).parameters
        context = parameters.any? do |type, name|
          [:key, :keyreq].include?(type) && name == :context
        end
        value = if context
          expression.function.call(*values, context: {})
        else
          expression.function.call(*values)
        end
        validate_finite_number(value)
        ValidationResult.new(true, value, domain || value_domain(value))
      rescue TypeError, NoMethodError, RangeError
        raise ArgumentError
      end
      private_class_method :validate_domains

      def self.validate_finite_number(value)
        if value.is_a?(Numeric) && value.respond_to?(:finite?) && !value.finite?
          raise ArgumentError
        end
      end
      private_class_method :validate_finite_number

      def self.value_domain(value)
        case value
        when Numeric
          :numeric
        when String
          :string
        when TrueClass, FalseClass
          :boolean
        when ::Time
          :time
        end
      end
      private_class_method :value_domain

      def self.validate_input_domains(name, results)
        case name
        when 'Number', 'Percentage', 'Time'
          validate_input_domain(results[0], [:numeric, :string])
        when 'Random'
          validate_input_domain(results[0], [:numeric])
        when 'PercentageOfActors'
          validate_input_domain(results[1], [:numeric])
        end
      end
      private_class_method :validate_input_domains

      def self.validate_input_domain(result, accepted)
        if result && result.domain && !accepted.include?(result.domain)
          raise ArgumentError
        end
      end
      private_class_method :validate_input_domain

      def self.validate_percentage(result)
        return unless result
        raise ArgumentError if result.domain && result.domain != :numeric
        return unless result.known

        value = result.value
        raise ArgumentError unless value.is_a?(Numeric)

        Flipper::Types::Percentage.new(value)
      end
      private_class_method :validate_percentage
    end
  end
end
