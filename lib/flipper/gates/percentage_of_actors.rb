module Flipper
  module Gates
    class PercentageOfActors < Gate
      Key = :perc_actors

      def type_key
        Key
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
        thing.is_a?(Flipper::Types::PercentageOfActors)
      end
    end
  end
end
