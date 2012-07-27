module Flipper
  module Toggles
    class Value < Toggle
      def enable(thing)
        @adapter.write @key, thing.enabled_value
      end

      def disable(thing)
        @adapter.write @key, thing.disabled_value
      end

      def value
        @adapter.read @key
      end
    end
  end
end
