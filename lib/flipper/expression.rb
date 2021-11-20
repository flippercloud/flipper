module Flipper
  class Expression
    SUPPORTED_TYPE_CLASSES = [
      String,
      Numeric,
      NilClass,
      TrueClass,
      FalseClass,
    ].freeze

    def self.build(object)
      return object if object.is_a?(Flipper::Expression)

      case object
      when Array
        object.map { |o| build(o) }
      when Hash
        type = object.keys.first
        args = object.values.first
        Expressions.const_get(type).new(args)
      when *SUPPORTED_TYPE_CLASSES
        object
      else
        raise ArgumentError, "#{object.inspect} cannot be converted into a rule expression"
      end
    end

    attr_reader :args

    def initialize(args)
      unless args.is_a?(Array)
        raise ArgumentError, "args must be an Array but was #{args.inspect}"
      end
      @args = self.class.build(args)
    end

    def eql?(other)
      self.class.eql?(other.class) && @args == other.args
    end
    alias_method :==, :eql?

    def value
      {
        self.class.name.split("::").last => args.map { |arg|
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

    def equal(object)
      Expressions::Equal.new([self, build(object)])
    end
    alias eq equal

    def not_equal(object)
      Expressions::NotEqual.new([self, build(object)])
    end
    alias neq not_equal

    def greater_than(object)
      Expressions::GreaterThan.new([self, build(object)])
    end
    alias gt greater_than

    def greater_than_or_equal(object)
      Expressions::GreaterThanOrEqual.new([self, build(object)])
    end
    alias gte greater_than_or_equal

    def less_than(object)
      Expressions::LessThan.new([self, build(object)])
    end
    alias lt less_than

    def less_than_or_equal(object)
      Expressions::LessThanOrEqual.new([self, build(object)])
    end
    alias lte less_than_or_equal

    def percentage(object)
      Expressions::Percentage.new([self, build(object)])
    end

    private

    def build(object)
      return object if object.is_a?(Flipper::Expression)

      case object
      when *SUPPORTED_TYPE_CLASSES
        Expression.build({"Value" => [object]})
      else
        raise ArgumentError, "#{object} is not a supported type"
      end
    end
  end
end

Dir[File.join(File.dirname(__FILE__), 'expressions', '*.rb')].sort.each do |file|
  require "flipper/expressions/#{File.basename(file, '.rb')}"
end
