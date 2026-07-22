require "flipper/expression/builder"
require "flipper/expression/constant"

module Flipper
  class Expression
    # Raised when expression data references an expression name this version
    # of flipper doesn't know (e.g. data written by a newer version). Inherits
    # from NameError so existing rescues keep working.
    UnknownExpression = Class.new(NameError)

    include Builder

    def self.build(object)
      return object if object.is_a?(self) || object.is_a?(Constant)

      case object
      when Hash
        name = object.keys.first
        args = object.values.first
        unless name
          raise ArgumentError, "#{object.inspect} cannot be converted into an expression"
        end

        new(name, Array(args).map { |o| build(o) })
      when String, Numeric, FalseClass, TrueClass
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
      @function = begin
        # inherit: false so unknown names raise instead of resolving to
        # top-level constants like ::Kernel or ::Array.
        Expressions.const_get(@name, false)
      rescue NameError
        raise UnknownExpression, "uninitialized constant Flipper::Expressions::#{@name}"
      end
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
