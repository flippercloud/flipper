module Flipper
  module Toggles
    class Set < Toggle
      def enable(thing)
        adapter.set_add adapter_key, thing.value
        true
      end

      def disable(thing)
        adapter.set_delete adapter_key, thing.value
        true
      end

      def value
        adapter.set_members adapter_key
      end

      def enabled?
        !value.empty?
      end
    end
  end
end
