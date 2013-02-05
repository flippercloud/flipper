module Flipper
  module Gates
    class Boolean < Gate
      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :boolean
      end

      # Internal: The piece of the adapter key that is unique to the gate class.
      def key
        :boolean
      end

      # Internal: The toggle class used to enable/disable the gate for a thing.
      def toggle_class
        Toggles::Boolean
      end

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if gate open for thing, false if not.
      def open?(thing)
        instrument(:open, thing) { |payload| toggle.value }
      end

      def protects?(thing)
        thing.is_a?(Flipper::Types::Boolean)
      end

      def description
        if enabled?
          'Enabled'
        else
          'Disabled'
        end
      end
    end
  end
end
