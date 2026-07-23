require "flipper/expression/builder"
require "flipper/expression/constant"
require "flipper/expression/schema"

module Flipper
  class Expression
    include Builder

    def self.build(object)
      return object if object.is_a?(self) || object.is_a?(Constant)

      case object
      when Hash
        unless object.size == 1
          raise ArgumentError, "#{object.inspect} cannot be converted into an expression"
        end

        name = object.keys.first
        args = object.values.first

        # Ensure args are an array, but don't use Array() because it would turn a
        # Hash (a nested expression) into an array of key/value pairs.
        args = args.is_a?(Hash) ? [args] : Array(args)

        new(name, args.map { |o| build(o) })
      when String, Numeric, FalseClass, TrueClass, NilClass
        Expression::Constant.new(object)
      when Symbol
        Expression::Constant.new(object.to_s)
      else
        raise ArgumentError, "#{object.inspect} cannot be converted into an expression"
      end
    end

    # Use #build
    private_class_method :new

    attr_reader :name, :function, :args

    def initialize(name, args = [])
      @name = name.to_s
      @function = Expressions.const_get(name)
      @args = args
    end

    def evaluate(context = {})
      if call_with_context?
        function.call(*args.map {|arg| arg.evaluate(context) }, context: context)
      else
        function.call(*args.map {|arg| arg.evaluate(context) })
      end
    end

    def eql?(other)
      other.is_a?(self.class) && @function == other.function && @args == other.args
    end
    alias_method :==, :eql?

    def value
      {
        name => args.map(&:value)
      }
    end

    # Public: Validate this expression against the JSON Schema. Returns an
    # Enumerable of validation errors (empty when valid). Requires json_schemer.
    def validate
      Schema.instance.validate(value)
    end

    # Public: Returns true if this expression is structurally valid.
    def valid?
      Schema.instance.valid?(value)
    end

    private

    def call_with_context?
      function.method(:call).parameters.any? do |type, name|
        name == :context && [:key, :keyreq].include?(type)
      end
    end
  end
end

Dir[File.join(File.dirname(__FILE__), 'expressions', '*.rb')].sort.each do |file|
  require "flipper/expressions/#{File.basename(file, '.rb')}"
end
