module Flipper
  module Gates
    class PercentageOfTime < Gate
      Key = :perc_time

      def key
        @key ||= "#{@feature.name}.#{Key}"
      end

      def toggle
        @toggle ||= Toggles::Value.new(@feature.adapter, key)
      end

      def match?(actor, time = Time.now)
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
