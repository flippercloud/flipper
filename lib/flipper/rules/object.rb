module Flipper
  module Rules
    class Object
      SUPPORTED_VALUE_TYPES_MAP = {
        String => "string",
        Integer => "integer",
        NilClass => "null",
        TrueClass => "boolean",
        FalseClass => "boolean",
        Array => "array",
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
          {"type" => "operator", "value" => "eq"},
          Rules::Object.new(object).to_h
        )
      end

      def neq(object)
        Flipper::Rules::Condition.new(
          to_h,
          {"type" => "operator", "value" => "neq"},
          Rules::Object.new(object).to_h
        )
      end

      def gt(object)
        Flipper::Rules::Condition.new(
          to_h,
          {"type" => "operator", "value" => "gt"},
          {"type" => "integer", "value" => require_integer(object)}
        )
      end

      def gte(object)
        Flipper::Rules::Condition.new(
          to_h,
          {"type" => "operator", "value" => "gte"},
          {"type" => "integer", "value" => require_integer(object)}
        )
      end

      def lt(object)
        Flipper::Rules::Condition.new(
          to_h,
          {"type" => "operator", "value" => "lt"},
          {"type" => "integer", "value" => require_integer(object)}
        )
      end

      def lte(object)
        Flipper::Rules::Condition.new(
          to_h,
          {"type" => "operator", "value" => "lte"},
          {"type" => "integer", "value" => require_integer(object)}
        )
      end

      def in(object)
        Flipper::Rules::Condition.new(
          to_h,
          {"type" => "operator", "value" => "in"},
          {"type" => "array", "value" => require_array(object)}
        )
      end

      def nin(object)
        Flipper::Rules::Condition.new(
          to_h,
          {"type" => "operator", "value" => "nin"},
          {"type" => "array", "value" => require_array(object)}
        )
      end

      def percentage(object)
        Flipper::Rules::Condition.new(
          to_h,
          {"type" => "operator", "value" => "percentage"},
          {"type" => "integer", "value" => require_integer(object)}
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

      def require_integer(object)
        raise ArgumentError, "object must be integer" unless object.is_a?(Integer)
        object
      end

      def require_array(object)
        raise ArgumentError, "object must be array" unless object.is_a?(Array)
        object
      end
    end
  end
end
