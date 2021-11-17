require "flipper/expression"

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
        expression = Flipper::Expression.build(data)
        result = expression.evaluate(
          feature_name: context.feature_name,
          properties: properties(context.thing)
        )
        !!result
      end

      def protects?(thing)
        thing.is_a?(Flipper::Expression)
      end

      private

      # Internal
      DEFAULT_PROPERTIES = {}.freeze

      def properties(actor)
        return DEFAULT_PROPERTIES if actor.nil?

        properties = {}

        if actor.respond_to?(:flipper_properties)
          properties.update(actor.flipper_properties)
        else
          warn "#{actor.inspect} does not respond to `flipper_properties` but should."
        end

        if actor.respond_to?(:flipper_id)
          properties["flipper_id".freeze] = actor.flipper_id
        end

        properties
      end
    end
  end
end
