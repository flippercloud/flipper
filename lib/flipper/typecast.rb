require 'set'

module Flipper
  module Typecast
    TruthMap = {
      true    => true,
      1       => true,
      'true'  => true,
      '1'     => true,
    }.freeze

    # Internal: Convert value to a boolean.
    #
    # Returns true or false.
    def self.to_boolean(value)
      !!TruthMap[value]
    end

    # Internal: Convert value to an integer.
    #
    # Returns an Integer representation of the value.
    # Raises ArgumentError if conversion is not possible.
    def self.to_integer(value)
      value.to_i
    rescue NoMethodError
      raise ArgumentError, "#{value.inspect} cannot be converted to an integer"
    end

    # Internal: Convert value to a float.
    #
    # Returns a Float representation of the value.
    # Raises ArgumentError if conversion is not possible.
    def self.to_float(value)
      value.to_f
    rescue NoMethodError
      raise ArgumentError, "#{value.inspect} cannot be converted to a float"
    end

    # Internal: Convert value to a number.
    #
    # Returns a Integer or Float representation of the value.
    # Raises ArgumentError if conversion is not possible.
    def self.to_number(value)
      case value
      when Numeric
        value
      when String
        value.include?('.') ? to_float(value) : to_integer(value)
      when NilClass
        0
      else
        value.to_f
      end
    rescue NoMethodError
      raise ArgumentError, "#{value.inspect} cannot be converted to a number"
    end
    singleton_class.send(:alias_method, :to_percentage, :to_number)

    # Internal: Convert value to a set.
    #
    # Returns a Set representation of the value.
    # Raises ArgumentError if conversion is not possible.
    def self.to_set(value)
      return value if value.is_a?(Set)
      return Set.new if value.nil? || value.empty?

      if value.respond_to?(:to_set)
        value.to_set
      else
        raise ArgumentError, "#{value.inspect} cannot be converted to a set"
      end
    end
  end
end
