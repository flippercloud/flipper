require "flipper/rules/condition"
require "flipper/rules/operator"

module Flipper
  module Rules
    class Object
      SUPPORTED_VALUE_TYPES_MAP = {
        String     => "string",
        Integer    => "integer",
        NilClass   => "null",
        TrueClass  => "boolean",
        FalseClass => "boolean",
        Array      => "array",
      }.freeze

      SUPPORTED_VALUE_TYPES = SUPPORTED_VALUE_TYPES_MAP.keys.freeze

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

      def eq(object)
        Flipper::Rules::Condition.new(
          to_h,
          Operator.new(:eq).to_h,
          self.class.primitive_or_property(object).to_h
        )
      end

      def neq(object)
        Flipper::Rules::Condition.new(
          to_h,
          Operator.new(:neq).to_h,
          self.class.primitive_or_property(object).to_h
        )
      end

      def gt(object)
        Flipper::Rules::Condition.new(
          to_h,
          Operator.new(:gt).to_h,
          self.class.integer_or_property(object)
        )
      end

      def gte(object)
        Flipper::Rules::Condition.new(
          to_h,
          Operator.new(:gte).to_h,
          self.class.integer_or_property(object)
        )
      end

      def lt(object)
        Flipper::Rules::Condition.new(
          to_h,
          Operator.new(:lt).to_h,
          self.class.integer_or_property(object)
        )
      end

      def lte(object)
        Flipper::Rules::Condition.new(
          to_h,
          Operator.new(:lte).to_h,
          self.class.integer_or_property(object)
        )
      end

      def in(object)
        Flipper::Rules::Condition.new(
          to_h,
          Operator.new(:in).to_h,
          self.class.array_or_property(object)
        )
      end

      def nin(object)
        Flipper::Rules::Condition.new(
          to_h,
          Operator.new(:nin).to_h,
          self.class.array_or_property(object)
        )
      end

      def percentage(object)
        Flipper::Rules::Condition.new(
          to_h,
          Operator.new(:percentage).to_h,
          self.class.integer_or_property(object)
        )
      end

      private

      def type_of(object)
        type_class = SUPPORTED_VALUE_TYPES.detect { |klass, type| object.is_a?(klass) }

        if type_class.nil?
          raise ArgumentError,
            "#{object.inspect} is not a supported primitive." +
            " Object must be one of: #{SUPPORTED_VALUE_TYPES.join(", ")}."
        end

        SUPPORTED_VALUE_TYPES_MAP[type_class]
      end

      def self.primitive_or_property(object)
        if object.is_a?(Flipper::Rules::Property)
          object
        else
          Object.new(object)
        end
      end

      def self.integer_or_property(object)
        case object
        when Integer
          {"type" => "integer", "value" => object}
        when Flipper::Rules::Property
          object.to_h
        else
          raise ArgumentError, "object must be integer or property" unless object.is_a?(Integer)
        end
      end

      def self.array_or_property(object)
        case object
        when Array
          {"type" => "array", "value" => object}
        when Flipper::Rules::Property
          object.to_h
        else
          raise ArgumentError, "object must be array or property" unless object.is_a?(Array)
        end
      end
    end
  end
end
