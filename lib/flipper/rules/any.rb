require 'flipper/rules/rule'

module Flipper
  module Rules
    class Any < Rule
      def self.build(*rules)
        new(rules.flatten.map { |rule| Flipper::Rules.build(rule) })
      end

      attr_reader :rules

      def initialize(*rules)
        @rules = rules.flatten
      end

      def all
        Flipper::Rules::All.new(self)
      end

      def any
        self
      end

      def value
        {
          "type" => self.class.name.split('::').last,
          "value" => @rules.map(&:value),
        }
      end

      def eql?(other)
        self.class.eql?(other.class) && @rules == other.rules
      end
      alias_method :==, :eql?

      def matches?(feature_name, actor)
        @rules.any? { |rule| rule.matches?(feature_name, actor) }
      end
    end
  end
end
