module Flipper
  module Adapters
    class Sync
      # Internal: Wraps a Synchronizer instance and only invokes it every
      # N milliseconds.
      class IntervalSynchronizer
        # Private: Number of milliseconds between syncs (default: 10 seconds).
        DEFAULT_INTERVAL_MS = 10_000

        # Private
        def self.now_ms
          Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
        end

        # Public: Initializes a new interval synchronizer.
        #
        # synchronizer - The Synchronizer to call when the interval has passed.
        # interval - The Integer number of milliseconds between invocations of
        #            the wrapped synchronizer.
        def initialize(synchronizer, interval: nil)
          @synchronizer = synchronizer
          @interval = interval || DEFAULT_INTERVAL_MS
          # TODO: add jitter to this so all processes booting at the same time
          # don't phone home at the same time.
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
          self.class.now_ms
        end
      end
    end
  end
end
