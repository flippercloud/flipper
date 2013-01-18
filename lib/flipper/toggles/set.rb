module Flipper
  module Toggles
    class Set < Toggle
      def enable(thing)
        super
        adapter.set_add adapter_key, thing.value
      end

      def disable(thing)
        super
        adapter.set_delete adapter_key, thing.value
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
