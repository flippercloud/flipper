module Flipper
  module Gates
    class DenyGroup < Gate
      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :deny_group
      end

      # Internal: Name converted to value safe for adapter.
      def key
        :deny_groups
      end

      def data_type
        :set
      end

      def enabled?(value)
        !value.empty?
      end

      def open?(context)
        false
      end

      def blocks?(context)
        return false unless context.actors?

        context.values.deny_groups.any? do |name|
          context.actors.any? do |actor|
            Flipper.group(name).match?(actor, context)
          end
        end
      end

      def deny?
        true
      end

      def wrap(thing)
        Types::Group.wrap(thing)
      end

      def protects?(thing)
        thing.is_a?(Types::Group) || thing.is_a?(Symbol)
      end
    end
  end
end
