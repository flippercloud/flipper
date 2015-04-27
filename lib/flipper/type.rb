module Flipper
  # Internal: Root class for all flipper types. You should never need to use this.
  class Type
    def self.wrap(value_or_instance)
      return value_or_instance if value_or_instance.is_a?(self)
      new(value_or_instance)
    end

    attr_reader :value

    def eql?(other)
      self.class.eql?(other.class) && value == other.value
    end
    alias_method :==, :eql?
  end
end

require 'flipper/types/actor'
require 'flipper/types/boolean'
require 'flipper/types/group'
require 'flipper/types/percentage'
require 'flipper/types/percentage_of_actors'
require 'flipper/types/percentage_of_time'
