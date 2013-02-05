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
        instrument(:open?, thing) { |payload|
          if thing.nil?
            false
          else
            enabled_groups.any? { |group| group.match?(thing) }
          end
        }
      end

      def protects?(thing)
        thing.is_a?(Flipper::Types::Group)
      end

      def description
        if enabled?
          "groups (#{toggle.value.to_a.sort.join(', ')})"
        else
          'disabled'
        end
      end

      # Private: Get all the enabled groups for this gate.
      #
      # Returns an Array of Flipper::Types::Group instances.
      def enabled_groups
        enabled_group_names.map { |name|
          begin
            Flipper.group(name)
          rescue GroupNotRegistered
            nil
          end
        }.compact
      end

      # Private: Get all the names of enabled groups.
      #
      # Returns a Set of the enabled group names.
      def enabled_group_names
        toggle.value
      end
    end
  end
end
