module Flipper
  module Gates
    class Boolean < Gate
      TruthMap = {
        true    => true,
        false   => false,
        'true'  => true,
        'false' => false,
        nil     => false,
      }

      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :boolean
      end

      # Internal: The piece of the adapter key that is unique to the gate class.
      def key
        :boolean
      end

      def data_type
        :boolean
      end

      def enabled?
        value
      end

      def value
        value = adapter.read(adapter_key)
        !!TruthMap[value]
      end

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if gate open for thing, false if not.
      def open?(thing, value)
        instrument(:open?, thing) { |payload| value }
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
