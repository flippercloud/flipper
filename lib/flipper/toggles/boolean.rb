module Flipper
  module Toggles
    class Boolean < Toggle
      def enable(thing)
        adapter.write key, thing.enabled_value
      end

      def disable(thing)
        adapter.delete key

        adapter.delete "#{gate.key_prefix}.#{Gates::Actor::Key}"
        adapter.delete "#{gate.key_prefix}.#{Gates::Group::Key}"
        adapter.delete "#{gate.key_prefix}.#{Gates::PercentageOfActors::Key}"
        adapter.delete "#{gate.key_prefix}.#{Gates::PercentageOfTime::Key}"
      end

      def value
        adapter.read key
      end
    end
  end
end
