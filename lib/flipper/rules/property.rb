module Flipper
  module Rules
    class Property
      def initialize(name)
        @name = name
      end

      def value
        {
          "type" => "property",
          "value" => @name,
        }
      end

      def eq(object)
        Flipper::Rules::Condition.new(
          value,
          {"type" => "operator", "value" => "eq"},
          {"type" => typeof(object), "value" => object}
        )
      end

      def neq(object)
        Flipper::Rules::Condition.new(
          value,
          {"type" => "operator", "value" => "neq"},
          {"type" => typeof(object), "value" => object}
        )
      end

      def gt(object)
        Flipper::Rules::Condition.new(
          value,
          {"type" => "operator", "value" => "gt"},
          {"type" => "integer", "value" => object}
        )
      end

      def gte(object)
        Flipper::Rules::Condition.new(
          value,
          {"type" => "operator", "value" => "gte"},
          {"type" => "integer", "value" => object}
        )
      end

      def lt(object)
        Flipper::Rules::Condition.new(
          value,
          {"type" => "operator", "value" => "lt"},
          {"type" => "integer", "value" => object}
        )
      end

      def lte(object)
        Flipper::Rules::Condition.new(
          value,
          {"type" => "operator", "value" => "lte"},
          {"type" => "integer", "value" => object}
        )
      end

      def in(object)
        Flipper::Rules::Condition.new(
          value,
          {"type" => "operator", "value" => "in"},
          {"type" => "array", "value" => object}
        )
      end

      def nin(object)
        Flipper::Rules::Condition.new(
          value,
          {"type" => "operator", "value" => "nin"},
          {"type" => "array", "value" => object}
        )
      end

      def percentage(object)
        Flipper::Rules::Condition.new(
          value,
          {"type" => "operator", "value" => "percentage"},
          {"type" => "integer", "value" => object}
        )
      end

      private

      def typeof(object)
        if object.is_a?(String)
          "string"
        elsif object.is_a?(Integer)
          "integer"
        elsif object.respond_to?(:to_a)
          "array"
        else
          raise "unsupported type inference for #{object.inspect}"
        end
      end
    end
  end
end
