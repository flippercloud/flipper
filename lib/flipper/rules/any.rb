module Flipper
  module Rules
    class Any
      def self.build(rules)
        new(*rules.map { |rule| Flipper::Rules.build(rule) })
      end

      def initialize(*rules)
        @rules = rules.flatten
      end

      def value
        {
          "type" => self.class.name.split('::').last,
          "value" => @rules.map(&:value),
        }
      end

      def matches?(feature_name, actor)
        @rules.any? { |rule| rule.matches?(feature_name, actor) }
      end
    end
  end
end
