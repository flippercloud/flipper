module Flipper
  module Toggles
    class Set < Toggle
      def enable(thing)
        adapter.set_add key, thing.enabled_value
      end

      def disable(thing)
        adapter.set_delete key, thing.disabled_value
      end

      def value
        adapter.set_members key
      end
    end
  end
end
