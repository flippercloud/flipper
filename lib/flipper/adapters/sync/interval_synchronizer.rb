module Flipper
  module Adapters
    class Sync
      # Internal: Wraps a Synchronizer instance and only invokes it every
      # N seconds.
      class IntervalSynchronizer
        # Private: Number of seconds between syncs (default: 10).
        DEFAULT_INTERVAL = 10

        # Public: The Float or Integer number of seconds between invocations of
        # the wrapped synchronizer.
        attr_reader :interval

        # Public: Initializes a new interval synchronizer.
        #
        # synchronizer - The Synchronizer to call when the interval has passed.
        # interval - The Integer number of seconds between invocations of
        #            the wrapped synchronizer.
        def initialize(synchronizer, interval: nil)
          @synchronizer = synchronizer
          @interval = interval || DEFAULT_INTERVAL
          # TODO: add jitter to this so all processes booting at the same time
          # don't phone home at the same time.
          @pid = Process.pid
          @last_sync_at = 0
          @syncing = false
          @sync_mutex = Mutex.new
        end

        def call
          reset_sync_state_if_forked
          return unless sync_needed?

          begin
            @synchronizer.call
          ensure
            complete_sync
          end

          nil
        end

        private

        def reset_sync_state_if_forked
          return if @pid == Process.pid

          @pid = Process.pid
          @syncing = false
          @sync_mutex = Mutex.new
        end

        def sync_needed?
          @sync_mutex.synchronize do
            current_time = now
            return false unless time_to_sync?(current_time)
            return false if @syncing

            @last_sync_at = current_time
            @syncing = true
            true
          end
        end

        def complete_sync
          @sync_mutex.synchronize do
            @syncing = false
          end
        end

        def time_to_sync?(current_time)
          seconds_since_last_sync = current_time - @last_sync_at
          seconds_since_last_sync >= @interval
        end

        def now
          Process.clock_gettime(Process::CLOCK_MONOTONIC, :second)
        end
      end
    end
  end
end
