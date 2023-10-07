module Flipper
  module Cloud
    class Telemetry
      attr_reader :storage

      def initialize
        @storage = Concurrent::Map.new { |features_hash, feature_key|
          features_hash.compute_if_absent(feature_key) {
            Concurrent::Map.new { |minutes_hash, minute|
              minutes_hash.compute_if_absent(minute) {
                Concurrent::Map.new { |values_hash, value|
                  values_hash.compute_if_absent(value) { Concurrent::AtomicFixnum.new(0) }
                }
              }
            }
          }
        }
      end

      # key => minute => true => count
      # key => minute => false => count
      def track_feature(key, value, minute: Time.now.to_i / 60 * 60)
        puts "#{key} #{minute} #{value}"
        @storage[key][minute][value].increment
      end
    end
  end
end
