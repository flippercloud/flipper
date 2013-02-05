module Flipper
  module Toggles
    class Boolean < Toggle
      def enable(thing)
        super
        adapter.write adapter_key, thing.value
        true
      end

      def disable(thing)
        super
        feature.gates.each do |gate|
          gate.adapter.delete gate.adapter_key
        end
        true
      end

      def value
        adapter.read adapter_key
      end

      def enabled?
        !!value
      end
    end
  end
end
