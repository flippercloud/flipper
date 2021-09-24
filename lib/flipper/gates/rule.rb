module Flipper
  module Gates
    class Rule < Gate
      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :rule
      end

      # Internal: Name converted to value safe for adapter.
      def key
        :rule
      end

      def data_type
        :json
      end

      def enabled?(value)
        value && !value.empty?
      end

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if gate open for thing, false if not.
      def open?(context)
        data = context.values[key]
        return false if data.nil? || data.empty?
        rule = Flipper::Rules.build(data)
        rule.matches?(context.feature_name, context.thing)
      end

      def protects?(thing)
        thing.is_a?(Flipper::Rules::Rule)
      end
    end
  end
end
