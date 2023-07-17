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
        if(object.keys.size != 1)
          raise ArgumentError, "#{object.inspect} cannot be converted into an expression"
        end

        name = object.keys.first
        args = object.values.first

        # Ensure args are an array, but we can't just use Array(args) because it will convert a Hash to Array
        args = args.is_a?(Hash) ? [args] : Array(args)

        new(name, args.map { |o| build(o) })
      when String, Numeric, FalseClass, TrueClass, nil
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

    def validate
      Schema.new.validate(value)
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
