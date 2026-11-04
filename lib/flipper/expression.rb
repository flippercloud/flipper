require "flipper/expression/builder"
require "flipper/expression/constant"

module Flipper
  class Expression
    # Raised when expression data references an expression name this version
    # of flipper doesn't know (e.g. data written by a newer version). Inherits
    # from NameError so existing rescues keep working.
    UnknownExpression = Class.new(NameError)

    include Builder

    PruneResult = Struct.new(:expression, :constant_value, keyword_init: true)
    private_constant :PruneResult

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
      when Array
        # A literal list (e.g. the right side of In/NotIn) becomes a single
        # constant holding the built element values. Building each element
        # normalizes it the same way a scalar constant would (Symbol => String).
        Expression::Constant.new(object.map { |element| build(element).value })
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
        # Only resolve constants defined directly on Expressions. const_get
        # accepts absolute and qualified names even when inherit is false.
        constant_name = @name.to_sym
        raise NameError unless Expressions.constants(false).include?(constant_name)

        Expressions.const_get(constant_name, false)
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

    # Public: Returns true if this expression contains an Any/All group with
    # no arguments anywhere in its tree. An empty All evaluates to true for
    # every actor and an empty Any to false for every actor, so persisting
    # one is almost always a mistake.
    def empty_groups?
      return true if group? && args.empty?

      args.any? { |arg| arg.is_a?(Expression) && arg.empty_groups? }
    end

    # Public: Returns a copy of this expression with empty Any/All groups
    # removed wherever removal cannot broaden the expression, or nil when no
    # conditions remain. An empty All can be removed from an All parent (it
    # contributes a constant true) and an empty Any from an Any parent (a
    # constant false), but an empty Any inside an All is kept because
    # removing it would broaden the expression from never-true.
    def prune_empty_groups
      prune_empty_groups_with_identity.expression
    end

    # Public: Returns true when this expression is guaranteed to match every
    # actor, e.g. an empty All group reaches an Any group or the root.
    def always_true?
      constant_group_value == true
    end

    def value
      {
        name => args.map(&:value)
      }
    end

    protected

    def prune_empty_groups_with_identity
      return PruneResult.new(expression: self) unless group?
      return PruneResult.new(constant_value: all?) if args.empty?

      pruned_args = args.map do |arg|
        if arg.is_a?(Expression)
          arg.prune_empty_groups_with_identity
        else
          PruneResult.new(expression: arg)
        end
      end

      kept = pruned_args.map do |result|
        if result.constant_value == false
          result.expression || build("Any" => []) if all?
        elsif result.constant_value.nil?
          result.expression
        end
      end.compact

      # No condition remains. Preserve this group's constant value for an
      # enclosing group, which lets an empty All disappear from All without
      # treating it as the unsafe empty-Any-in-All case.
      if kept.empty?
        return PruneResult.new(constant_value: constant_group_value)
      end

      pruned = build(name => kept)
      PruneResult.new(
        expression: pruned,
        constant_value: pruned.constant_group_value
      )
    end

    def constant_group_value
      return nil unless group?
      return all? if args.empty?

      values = args.map do |arg|
        arg.is_a?(Expression) ? arg.constant_group_value : nil
      end

      if all?
        return false if values.include?(false)
        return true if values.all?(true)
      else
        return true if values.include?(true)
        return false if values.all?(false)
      end

      nil
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
