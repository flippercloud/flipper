module Flipper
  class Expression
    SUPPORTED_TYPES_MAP = {
      String     => "String",
      Numeric    => "Number",
      NilClass   => "Null",
      TrueClass  => "Boolean",
      FalseClass => "Boolean",
    }.freeze

    SUPPORTED_TYPE_CLASSES = SUPPORTED_TYPES_MAP.keys.freeze
    SUPPORTED_TYPE_NAMES = SUPPORTED_TYPES_MAP.values.freeze

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
      Expressions::Equal.new([self, Expression.build(typed(object))])
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
      Expressions::GreaterThanOrEqualTo.new([self, build(object)])
    end
    alias gte greater_than_or_equal

    def less_than(object)
      Expressions::LessThan.new([self, build(object)])
    end
    alias lt less_than

    def less_than_or_equal(object)
      Expressions::LessThanOrEqualTo.new([self, build(object)])
    end
    alias lte less_than_or_equal

    def percentage(object)
      Expressions::Percentage.new([self, build(object)])
    end

    private

    def build(object)
      Expression.build(typed(object))
    end

    def typed(object)
      {type_of(object) => [object]}
    end

    def type_of(object)
      type_class = SUPPORTED_TYPE_CLASSES.detect { |klass, type| object.is_a?(klass) }

      if type_class.nil?
        raise ArgumentError,
          "#{object.inspect} is not a supported primitive." +
          " Object must be one of: #{SUPPORTED_TYPE_CLASSES.join(", ")}."
      end

      SUPPORTED_TYPES_MAP[type_class]
    end
  end
end

Dir[File.join(File.dirname(__FILE__), 'expressions', '*.rb')].sort.each do |file|
  require "flipper/expressions/#{File.basename(file, '.rb')}"
end
