require 'flipper/rules/any'

module Flipper
  module Rules
    class All < Any
      def matches?(feature_name, actor)
        @rules.all? { |rule| rule.matches?(feature_name, actor) }
      end
    end
  end
end
