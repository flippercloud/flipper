module Flipper
  module Gates
    class PercentageOfRandom < Gate
      Key = :perc_time

      def type_key
        Key
      end

      def open?(actor)
        percentage = toggle.value.to_i

        rand < (percentage / 100.0)
      end

      def protects?(thing)
        thing.is_a?(Flipper::Types::PercentageOfRandom)
      end
    end
  end
end
