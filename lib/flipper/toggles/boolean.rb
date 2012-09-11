module Flipper
  module Toggles
    class Boolean < Toggle
      def enable(thing)
        super
        adapter.write key, thing.value
      end

      def disable(thing)
        super
        feature.gates.each do |gate|
          gate.adapter.delete gate.key
        end
      end

      def value
        adapter.read key
      end
    end
  end
end
