module Flipper
  module Toggles
    class Boolean < Toggle
      def enable(thing)
        adapter.write key, thing.enabled_value
      end

      def disable(thing)
        adapter.delete key
        adapter.delete Key.new(key.prefix, Gates::Actor::Key)
        adapter.delete Key.new(key.prefix, Gates::Group::Key)
        adapter.delete Key.new(key.prefix, Gates::PercentageOfActors::Key)
        adapter.delete Key.new(key.prefix, Gates::PercentageOfRandom::Key)
      end

      def value
        adapter.read key
      end
    end
  end
end
