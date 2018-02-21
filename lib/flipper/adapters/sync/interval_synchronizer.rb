module Flipper
  module Adapters
    class Sync
      # Internal: Wraps a Synchronizer instance and only invokes it every
      # N milliseconds.
      class IntervalSynchronizer
        # Private: Default to syncing every 10 seconds.
        DEFAULT_INTERVAL_MS = 10_000

        def initialize(synchronizer, interval: nil)
          @synchronizer = synchronizer
          @interval = interval || DEFAULT_INTERVAL_MS
          @last_sync_at = 0
        end

        def call
          return unless time_to_sync?

          @last_sync_at = now_ms
          @synchronizer.call

          nil
        end

        private

        def time_to_sync?
          (now_ms - @last_sync_at) >= @interval
        end

        def now_ms
          Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
        end
      end
    end
  end
end
