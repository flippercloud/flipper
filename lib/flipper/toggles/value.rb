module Flipper
  module Toggles
    class Value < Toggle
      def enable(thing)
        super
        adapter.write key, thing.value
      end

      def disable(thing)
        super
        adapter.delete key
      end

      def value
        adapter.read key
      end
    end
  end
end
