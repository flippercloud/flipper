require 'set'
require 'flipper/typecast'

module Flipper
  class GateValues
    attr_reader :boolean
    attr_reader :actors
    attr_reader :groups
    attr_reader :expression
    attr_reader :percentage_of_actors
    attr_reader :percentage_of_time
    attr_reader :block_actors
    attr_reader :block_groups

    def initialize(adapter_values)
      @boolean = Typecast.to_boolean(adapter_values[:boolean])
      @actors = Typecast.to_set(adapter_values[:actors])
      @groups = Typecast.to_set(adapter_values[:groups])
      @expression = adapter_values[:expression]
      @percentage_of_actors = Typecast.to_number(adapter_values[:percentage_of_actors])
      @percentage_of_time = Typecast.to_number(adapter_values[:percentage_of_time])
      @block_actors = Typecast.to_set(adapter_values[:block_actors])
      @block_groups = Typecast.to_set(adapter_values[:block_groups])
    end

    def eql?(other)
      self.class.eql?(other.class) &&
        boolean == other.boolean &&
        actors == other.actors &&
        groups == other.groups &&
        expression == other.expression &&
        percentage_of_actors == other.percentage_of_actors &&
        percentage_of_time == other.percentage_of_time &&
        block_actors == other.block_actors &&
        block_groups == other.block_groups
    end
    alias_method :==, :eql?
  end
end
