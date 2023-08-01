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

    # Internal: Convert value to a percentage.
    #
    # Returns a Integer or Float representation of the value.
    # Raises ArgumentError if conversion is not possible.
    def self.to_percentage(value)
      result_to_f = value.to_f
      result_to_i = result_to_f.to_i
      result_to_f == result_to_i ? result_to_i : result_to_f
    rescue NoMethodError
      raise ArgumentError, "#{value.inspect} cannot be converted to a percentage"
    end

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

    def self.features_hash(source)
      normalized_source = {}
      (source || {}).each do |feature_key, gates|
        normalized_source[feature_key] ||= {}
        gates.each do |gate_key, value|
          normalized_value = case value
          when Array, Set
            value.to_set
          else
            value ? value.to_s : value
          end
          normalized_source[feature_key][gate_key.to_sym] = normalized_value
        end
      end
      normalized_source
    end
  end
end
