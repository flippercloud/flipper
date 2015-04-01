module Flipper
  class GateValues
    TruthMap = {
      true    => true,
      1       => true,
      "true"  => true,
      "1"     => true,
    }

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
      if value.respond_to?(:to_i)
        value.to_i
      else
        raise ArgumentError, "#{value.inspect} cannot be converted to an integer"
      end
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

    attr_reader :boolean
    attr_reader :actors
    attr_reader :groups
    attr_reader :percentage_of_actors
    attr_reader :percentage_of_random

    def initialize(adapter_values)
      @boolean = self.class.to_boolean(adapter_values[:boolean])
      @actors = self.class.to_set(adapter_values[:actors])
      @groups = self.class.to_set(adapter_values[:groups])
      @percentage_of_actors = self.class.to_integer(adapter_values[:percentage_of_actors])
      @percentage_of_random = self.class.to_integer(adapter_values[:percentage_of_random])
    end

    def [](key)
      instance_variable_get("@#{key}")
    end

    def eql?(other)
      self.class.eql?(other.class) &&
        boolean == other.boolean &&
        actors == other.actors &&
        groups == other.groups &&
        percentage_of_actors == other.percentage_of_actors &&
        percentage_of_random == other.percentage_of_random
    end
    alias_method :==, :eql?
  end
end
