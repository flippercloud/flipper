module Flipper
  module Gates
    class PercentageOfTime < Gate
      Key = :perc_time

      def type_key
        Key
      end

      def open?(actor, time = Time.now)
        percentage = toggle.value

        if percentage.nil?
          false
        else
          time.to_i % 100 < percentage
        end
      end

      def protects?(thing)
        thing.is_a?(Flipper::Types::PercentageOfTime)
      end
    end
  end
end
