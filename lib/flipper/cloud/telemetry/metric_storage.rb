require 'concurrent/map'
require 'concurrent/atomic/atomic_fixnum'

module Flipper
  module Cloud
    class Telemetry
      class MetricStorage
        def initialize
          @storage = Concurrent::Map.new { |h, k| h[k] = Concurrent::AtomicFixnum.new(0) }
        end

        def increment(metric)
          @storage[metric].increment
        end

        def drain
          metrics = {}
          @storage.keys.each do |metric|
            metrics[metric] = @storage.delete(metric).value
          end
          metrics.freeze
        end

        def empty?
          @storage.empty?
        end
      end
    end
  end
end
