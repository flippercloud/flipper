module Flipper
  module Toggles
    class Boolean < Toggle
      def enable(thing)
        adapter.write key, thing.enabled_value
      end

      def disable(thing)
        adapter.delete key

        adapter.delete "#{gate.key_prefix}#{Gate::Separator}#{Gates::Actor::Key}"
        adapter.delete "#{gate.key_prefix}#{Gate::Separator}#{Gates::Group::Key}"
        adapter.delete "#{gate.key_prefix}#{Gate::Separator}#{Gates::PercentageOfActors::Key}"
        adapter.delete "#{gate.key_prefix}#{Gate::Separator}#{Gates::PercentageOfTime::Key}"
      end

      def value
        adapter.read key
      end
    end
  end
end
