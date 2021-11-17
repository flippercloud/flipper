module Flipper
  class Expression
    def self.build(object)
      return object if object.is_a?(Flipper::Expression)

      case object
      when Array
        object.map { |o| build(o) }
      when Hash
        type = object.keys.first
        args = object.values.first
        Expressions.const_get(type).new(args)
      when String, Symbol, Numeric, TrueClass, FalseClass
        object
      else
        raise ArgumentError, "#{object.inspect} cannot be converted into a rule expression"
      end
    end

    attr_reader :args

    def initialize(args)
      @args = self.class.build(args)
    end

    def eql?(other)
      self.class.eql?(other.class) && @args == other.args
    end
    alias_method :==, :eql?

    def value
      {
        self.class.name => args.map { |arg|
          arg.is_a?(Expression) ? arg.value : arg
        }
      }
    end

    def add(*expressions)
      any.add(*expressions)
    end

    def remove(*expressions)
      any.remove(*expressions)
    end

    def any
      Expressions::Any.new([self])
    end

    def all
      Expressions::All.new([self])
    end

    def eq(*args)
      Expressions::Equal.new([self].concat(args))
    end

    def neq(*args)
      Expressions::NotEqual.new([self].concat(args))
    end

    #####################################################################
    # TODO: convert naked primitive to Number, String, Boolean, etc.
    #####################################################################
    def gt(*args)
      Expressions::GreaterThan.new([self].concat(args))
    end

    def gte(*args)
      Expressions::GreaterThan.new([self].concat(args))
    end

    def lt(*args)
      Expressions::GreaterThan.new([self].concat(args))
    end

    def lte(*args)
      Expressions::GreaterThan.new([self].concat(args))
    end
  end
end

require "flipper/expressions/any"
require "flipper/expressions/all"
require "flipper/expressions/boolean"
require "flipper/expressions/equal"
require "flipper/expressions/greater_than_or_equal_to"
require "flipper/expressions/greater_than"
require "flipper/expressions/less_than_or_equal_to"
require "flipper/expressions/less_than"
require "flipper/expressions/not_equal"
require "flipper/expressions/number"
require "flipper/expressions/percentage"
require "flipper/expressions/property"
require "flipper/expressions/random"
require "flipper/expressions/string"
