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
        unless type
          raise ArgumentError, "#{object.inspect} cannot be converted into an expression"
        end
        Expressions.const_get(type).new(args)
      when String, Numeric, FalseClass, TrueClass
        Expressions::Constant.new(object)
      when Symbol
        Expressions::Constant.new(object.to_s)
      else
        raise ArgumentError, "#{object.inspect} cannot be converted into an expression"
      end
    end

    attr_reader :args

    def initialize(args = [])
      args = [args] unless args.is_a?(Array)
      @args = self.class.build(args)
    end

    def evaluate(context = {})
      if call_with_context?
        call(*args.map { |arg| arg.evaluate(context) }, context: context)
      else
        call(*args.map { |arg| arg.evaluate(context) })
      end
    end

    def eql?(other)
      self.class.eql?(other.class) && @args == other.args
    end
    alias_method :==, :eql?

    def value
      {
        self.class.name.split("::").last => args.map(&:value)
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
      Expressions::Equal.new([self, self.class.build(object)])
    end
    alias eq equal

    def not_equal(object)
      Expressions::NotEqual.new([self, self.class.build(object)])
    end
    alias neq not_equal

    def greater_than(object)
      Expressions::GreaterThan.new([self, self.class.build(object)])
    end
    alias gt greater_than

    def greater_than_or_equal_to(object)
      Expressions::GreaterThanOrEqualTo.new([self, self.class.build(object)])
    end
    alias gte greater_than_or_equal_to
    alias greater_than_or_equal greater_than_or_equal_to

    def less_than(object)
      Expressions::LessThan.new([self, self.class.build(object)])
    end
    alias lt less_than

    def less_than_or_equal_to(object)
      Expressions::LessThanOrEqualTo.new([self, self.class.build(object)])
    end
    alias lte less_than_or_equal_to
    alias less_than_or_equal less_than_or_equal_to

    def percentage_of_actors(object)
      Expressions::PercentageOfActors.new([self, self.class.build(object)])
    end

    private

    def evaluate_arg(index, context = {})
      object = args[index].evaluate(context)
    end

    def call_with_context?
      method(:call).parameters.any? do |type, name|
        name == :context && [:key, :keyreq].include?(type)
      end
    end
  end
end

Dir[File.join(File.dirname(__FILE__), 'expressions', '*.rb')].sort.each do |file|
  require "flipper/expressions/#{File.basename(file, '.rb')}"
end
