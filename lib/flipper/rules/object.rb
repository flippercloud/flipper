require "flipper/rules/condition"
require "flipper/rules/operator"

module Flipper
  module Rules
    class Object
      SUPPORTED_TYPES_MAP = {
        String     => "String",
        Integer    => "Integer",
        NilClass   => "Null",
        TrueClass  => "Boolean",
        FalseClass => "Boolean",
      }.freeze

      SUPPORTED_TYPE_CLASSES = SUPPORTED_TYPES_MAP.keys.freeze
      SUPPORTED_TYPE_NAMES = SUPPORTED_TYPES_MAP.values.freeze

      def self.build(object)
        return object if object.is_a?(Flipper::Rules::Object)

        if object.is_a?(Hash)
          type = object.fetch("type")
          value = object.fetch("value")

          if SUPPORTED_TYPE_NAMES.include?(type)
            new(value)
          else
            Rules.const_get(type).new(value)
          end
        else
          new(object)
        end
      end

      attr_reader :type, :value

      def initialize(value)
        @type = type_of(value)
        @value = value
      end

      def to_h
        {
          "type" => @type,
          "value" => @value,
        }
      end

      def eql?(other)
        self.class.eql?(other.class) &&
          @type == other.type &&
          @value == other.value
      end
      alias_method :==, :eql?

      def evaluate(properties)
        return nil if type == "Null".freeze
        value
      end

      def eq(object)
        Flipper::Rules::Condition.new(
          self, Operators::Eq.new, self.class.primitive_or_object(object)
        )
      end

      def neq(object)
        Flipper::Rules::Condition.new(
          self, Operators::Neq.new, self.class.primitive_or_object(object)
        )
      end

      def gt(object)
        Flipper::Rules::Condition.new(
          self, Operators::Gt.new, self.class.integer_or_object(object)
        )
      end

      def gte(object)
        Flipper::Rules::Condition.new(
          self, Operators::Gte.new, self.class.integer_or_object(object)
        )
      end

      def lt(object)
        Flipper::Rules::Condition.new(
          self, Operators::Lt.new, self.class.integer_or_object(object)
        )
      end

      def lte(object)
        Flipper::Rules::Condition.new(
          self, Operators::Lte.new, self.class.integer_or_object(object)
        )
      end

      def percentage(object)
        Flipper::Rules::Condition.new(
          self, Operators::Percentage.new, self.class.integer_or_object(object)
        )
      end

      private

      def type_of(object)
        type_class = SUPPORTED_TYPE_CLASSES.detect { |klass, type| object.is_a?(klass) }

        if type_class.nil?
          raise ArgumentError,
            "#{object.inspect} is not a supported primitive." +
            " Object must be one of: #{SUPPORTED_TYPE_CLASSES.join(", ")}."
        end

        SUPPORTED_TYPES_MAP[type_class]
      end

      def self.primitive_or_object(object)
        if object.is_a?(Flipper::Rules::Object)
          object
        else
          Object.new(object)
        end
      end

      def self.integer_or_object(object)
        case object
        when Integer
          Object.new(object)
        when Flipper::Rules::Object
          object
        else
          raise ArgumentError, "object must be integer or property" unless object.is_a?(Integer)
        end
      end

      def self.array_or_object(object)
        case object
        when Array
          Object.new(object)
        when Flipper::Rules::Object
          object
        else
          raise ArgumentError, "object must be array or property" unless object.is_a?(Array)
        end
      end
    end
  end
end
