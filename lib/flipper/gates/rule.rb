module Flipper
  module Gates
    class Rule < Gate
      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :rule
      end

      # Internal: Name converted to value safe for adapter.
      def key
        :rules
      end

      def data_type
        :json
      end

      def enabled?(value)
        !value.empty?
      end

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if gate open for thing, false if not.
      def open?(context)
        rules = context.values[key]
        rules.any? { |hash|
          rule = Flipper::Rules.build(hash)
          rule.open?(context.feature_name, context.thing)
        }
      end

      def protects?(thing)
        thing.is_a?(Flipper::Rules::Condition) ||
          thing.is_a?(Flipper::Rules::Any) ||
          thing.is_a?(Flipper::Rules::All)
      end
    end
  end
end
