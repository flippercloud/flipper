module Flipper
  module Toggles
    class Set < Toggle
      def enable(thing)
        super
        adapter.set_add key, thing.value
      end

      def disable(thing)
        super
        adapter.set_delete key, thing.value
      end

      def value
        adapter.set_members key
      end
    end
  end
end
