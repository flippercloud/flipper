module Flipper
  module Gates
    class Group < Gate
      def initialize(group_resolver: Flipper)
        @group_resolver = group_resolver
      end

      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :group
      end

      # Internal: Name converted to value safe for adapter.
      def key
        :groups
      end

      def data_type
        :set
      end

      def enabled?(value)
        !value.empty?
      end

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if gate open for thing, false if not.
      def open?(context)
        return false unless context.actors?

        context.values.groups.any? do |name|
          context.actors.any? do |actor|
            @group_resolver.group(name).match?(actor, context)
          end
        end
      end

      def wrap(thing)
        return thing if thing.is_a?(Types::Group)

        @group_resolver.group(thing)
      end

      def protects?(thing)
        thing.is_a?(Types::Group) || thing.is_a?(Symbol)
      end
    end
  end
end
