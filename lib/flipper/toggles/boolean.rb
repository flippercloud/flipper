module Flipper
  module Toggles
    class Boolean < Toggle
      def enable(thing)
        super
        adapter.write adapter_key, thing.value
      end

      def disable(thing)
        super
        feature.gates.each do |gate|
          gate.adapter.delete gate.adapter_key
        end
      end

      def value
        adapter.read adapter_key
      end
    end
  end
end
