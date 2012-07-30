module Flipper
  module Toggles
    class Boolean < Toggle
      def enable(thing)
        @adapter.write @key, thing.enabled_value
      end

      def disable(thing)
        feature_prefix = @key.split('.').first
        @adapter.delete "#{feature_prefix}.#{Gates::Actor::Key}"
        @adapter.delete "#{feature_prefix}.#{Gates::Boolean::Key}"
        @adapter.delete "#{feature_prefix}.#{Gates::Group::Key}"
        @adapter.delete "#{feature_prefix}.#{Gates::PercentageOfActors::Key}"
        @adapter.delete "#{feature_prefix}.#{Gates::PercentageOfTime::Key}"
      end

      def value
        @adapter.read @key
      end
    end
  end
end
