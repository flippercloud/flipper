module Flipper
  class All
    def initialize(*rules)
      @rules = rules
    end

    def value
      {
        "type" => "All",
        "value" => @rules.map(&:value),
      }
    end

    def open?(feature_name, actor)
      @rules.all? { |rule| rule.open?(feature_name, actor) }
    end
  end
end
