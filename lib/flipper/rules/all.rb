require 'flipper/rules/any'

module Flipper
  module Rules
    class All < Any
      def all
        self
      end

      def any
        Flipper::Rules::Any.new(self)
      end

      def matches?(feature_name, actor)
        @rules.all? { |rule| rule.matches?(feature_name, actor) }
      end
    end
  end
end
