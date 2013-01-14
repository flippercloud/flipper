module Flipper
  module Gates
    class PercentageOfRandom < Gate
      def name
        :percentage_of_random
      end

      def key
        :perc_time
      end

      def open?(thing)
        instrument(:open, thing) {
          percentage = toggle.value.to_i

          rand < (percentage / 100.0)
        }
      end

      def protects?(thing)
        thing.is_a?(Flipper::Types::PercentageOfRandom)
      end
    end
  end
end
