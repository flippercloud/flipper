module Flipper
  class GateValues
    attr_reader :boolean
    attr_reader :actors
    attr_reader :groups
    attr_reader :percentage_of_actors
    attr_reader :percentage_of_random

    def initialize(adapter_values)
      @boolean = adapter_values[:boolean]
      @actors = adapter_values[:actors]
      @groups = adapter_values[:groups]
      @percentage_of_actors = adapter_values[:percentage_of_actors].to_i
      @percentage_of_random = adapter_values[:percentage_of_random].to_i
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
