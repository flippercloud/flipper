module Flipper
  module Rules
    module Operators
      class Base
        attr_reader :type, :value

        def initialize(value)
          @type = "Operator".freeze
          @value = value.to_s
        end

        def name
          @value
        end

        def to_h
          {
            "type" => @type,
            "value" => @value,
          }
        end

        def eql?(other)
          self.class.eql?(other.class) &&
            @type == other.type &&
            @value == other.value
        end
        alias_method :==, :eql?

        def call(*args)
          raise NotImplementedError
        end
      end
    end
  end
end
