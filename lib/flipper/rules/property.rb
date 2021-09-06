module Flipper
  module Rules
    class Property
      attr_reader :name

      def initialize(name)
        @name = name.to_s
      end

      def value
        {
          "type" => "property",
          "value" => @name,
        }
      end

      def eql?(other)
        self.class.eql?(other.class) &&
          @name == other.name
      end
      alias_method :==, :eql?

      def eq(object)
        type, object = Rules.typed(object)
        Flipper::Rules::Condition.new(
          value,
          {"type" => "operator", "value" => "eq"},
          {"type" => type, "value" => object}
        )
      end

      def neq(object)
        type, object = Rules.typed(object)
        Flipper::Rules::Condition.new(
          value,
          {"type" => "operator", "value" => "neq"},
          {"type" => type, "value" => object}
        )
      end

      def gt(object)
        Flipper::Rules::Condition.new(
          value,
          {"type" => "operator", "value" => "gt"},
          {"type" => "integer", "value" => Rules.require_integer(object)}
        )
      end

      def gte(object)
        Flipper::Rules::Condition.new(
          value,
          {"type" => "operator", "value" => "gte"},
          {"type" => "integer", "value" => Rules.require_integer(object)}
        )
      end

      def lt(object)
        Flipper::Rules::Condition.new(
          value,
          {"type" => "operator", "value" => "lt"},
          {"type" => "integer", "value" => Rules.require_integer(object)}
        )
      end

      def lte(object)
        Flipper::Rules::Condition.new(
          value,
          {"type" => "operator", "value" => "lte"},
          {"type" => "integer", "value" => Rules.require_integer(object)}
        )
      end

      def in(object)
        Flipper::Rules::Condition.new(
          value,
          {"type" => "operator", "value" => "in"},
          {"type" => "array", "value" => Rules.require_array(object)}
        )
      end

      def nin(object)
        Flipper::Rules::Condition.new(
          value,
          {"type" => "operator", "value" => "nin"},
          {"type" => "array", "value" => Rules.require_array(object)}
        )
      end

      def percentage(object)
        Flipper::Rules::Condition.new(
          value,
          {"type" => "operator", "value" => "percentage"},
          {"type" => "integer", "value" => Rules.require_integer(object)}
        )
      end
    end
  end
end
