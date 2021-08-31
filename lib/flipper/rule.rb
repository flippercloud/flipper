module Flipper
  class Rule

    def self.from_hash(hash)
      value = hash.fetch("value")
      new(value.fetch("left"), value.fetch("operator"), value.fetch("right"))
    end

    def initialize(left, operator, right)
      @left = left
      @operator = operator
      @right = right
    end

    def value
      {
        "type" => "Rule",
        "value" => {
          "left" => @left,
          "operator" => @operator,
          "right" => @right,
        }
      }
    end

    def open?(feature_name, actor)
      attributes = actor.flipper_properties
      left_value = evaluate(@left, attributes)
      right_value = evaluate(@right, attributes)
      operator_name = @operator.fetch("value")

      !! case operator_name
      when "eq"
        left_value == right_value
      when "neq"
        left_value != right_value
      when "gt"
        left_value && right_value && left_value > right_value
      when "gte"
        left_value && right_value && left_value >= right_value
      when "lt"
        left_value && right_value && left_value < right_value
      when "lte"
        left_value && right_value && left_value <= right_value
      when "in"
        left_value && right_value && right_value.include?(left_value)
      when "nin"
        left_value && right_value && !right_value.include?(left_value)
      when "percentage"
        # this is to support up to 3 decimal places in percentages
        scaling_factor = 1_000
        id = "#{feature_name}#{left_value}"
        left_value && right_value && (Zlib.crc32(id) % (100 * scaling_factor) < right_value * scaling_factor)
      else
        raise "operator not implemented: #{operator_name}"
      end
    end

    private

    def evaluate(hash, attributes)
      type = hash.fetch("type")

      case type
      when "property"
        attributes[hash.fetch("value")]
      when "array"
        hash.fetch("value")
      when "string"
        hash.fetch("value")
      when "random"
        rand hash.fetch("value")
      when "integer"
        hash.fetch("value")
      else
        raise "type not found: #{type.inspect}"
      end
    end
  end
end
