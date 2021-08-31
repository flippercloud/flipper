module Flipper
  class Any
    def initialize(*rules)
      @rules = rules
    end

    def value
      {
        "type" => "Any",
        "value" => @rules.map(&:value),
      }
    end

    def open?(feature_name, actor)
      @rules.any? { |rule| rule.open?(feature_name, actor) }
    end
  end
end
