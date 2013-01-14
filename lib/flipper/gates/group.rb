module Flipper
  module Gates
    class Group < Gate
      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :group
      end

      # Internal: The piece of the adapter key that is unique to the gate class.
      def key
        :groups
      end

      # Internal: The toggle class used to enable/disable the gate for a thing.
      def toggle_class
        Toggles::Set
      end

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if gate open for thing, false if not.
      def open?(thing)
        instrument(:open, thing) {
          if thing.nil?
            false
          else
            groups.any? { |group| group.match?(thing) }
          end
        }
      end

      def group_names
        toggle.value
      end

      def groups
        group_names.map { |name| Flipper.group(name) }.compact
      end

      def protects?(thing)
        thing.is_a?(Flipper::Types::Group)
      end
    end
  end
end
