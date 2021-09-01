require 'flipper/rules/all'

module Flipper
  module Rules
    class All < Any
      def open?(feature_name, actor)
        @rules.all? { |rule| rule.open?(feature_name, actor) }
      end
    end
  end
end
