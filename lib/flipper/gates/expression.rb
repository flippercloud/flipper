require "flipper/expression"

module Flipper
  module Gates
    class Expression < Gate
      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :expression
      end

      # Internal: Name converted to value safe for adapter.
      def key
        :expression
      end

      def data_type
        :json
      end

      def enabled?(value)
        !value.nil? && !value.empty?
      end

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if gate open for thing, false if not.
      def open?(context)
        data = context.values.expression
        return false if data.nil? || data.empty?

        begin
          expression = Flipper::Expression.build(data)
        rescue Flipper::Expression::UnknownExpression => e
          warn "Feature #{context.feature_name.inspect} uses an expression this version of flipper doesn't know (#{e.message}). Treating the expression as disabled. Upgrade the flipper gem to evaluate it."
          return false
        end

        if context.actors.nil? || context.actors.empty?
          !!expression.evaluate(feature_name: context.feature_name, properties: DEFAULT_PROPERTIES, actor: nil)
        else
          context.actors.any? do |actor|
            !!expression.evaluate(feature_name: context.feature_name, properties: properties(actor), actor: actor)
          end
        end
      end

      def protects?(thing)
        thing.is_a?(Flipper::Expression) || thing.is_a?(Hash)
      end

      def wrap(thing)
        Flipper::Expression.build(thing)
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

        properties.transform_keys!(&:to_s)

        if actor.respond_to?(:flipper_id)
          properties["flipper_id".freeze] = actor.flipper_id
        end

        properties
      end
    end
  end
end
