module Flipper
  module Gates
    class PercentageOfActors < Gate
      Key = :perc_actors

      def key
        @key ||= "#{@feature.name}.#{Key}"
      end

      def toggle
        @toggle ||= Toggles::Value.new(@feature.adapter, key)
      end

      def match?(actor)
        percentage = toggle.value

        if percentage.nil?
          false
        else
          actor.identifier % 100 < percentage
        end
      end

      def protects?(thing)
        thing.is_a?(Flipper::PercentageOfActors)
      end
    end
  end
end
