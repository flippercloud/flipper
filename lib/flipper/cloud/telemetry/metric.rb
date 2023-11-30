module Flipper
  module Cloud
    class Telemetry
      class Metric
        attr_reader :key, :time, :result

        def initialize(key, result, time = Time.now)
          @key = key
          @result = result
          @time = time.to_i / 60 * 60
        end

        def as_json(options = {})
          data = {
            "key" => key.to_s,
            "time" => time,
            "result" => result,
          }

          if options[:with]
            data.merge!(options[:with])
          end

          data
        end

        def eql?(other)
          self.class.eql?(other.class) &&
            @key == other.key && @time == other.time && @result == other.result
        end
        alias :== :eql?

        def hash
          [self.class, @key, @time, @result].hash
        end
      end
    end
  end
end
