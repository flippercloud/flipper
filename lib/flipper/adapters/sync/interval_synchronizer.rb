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
          @mutex = Mutex.new
          @pid = Process.pid
          @syncing = false
          @last_sync_at = 0
        end

        def call
          return unless sync_needed?

          begin
            @synchronizer.call
          ensure
            complete_sync
          end

          nil
        end

        private

        def sync_needed?
          return false unless @mutex.try_lock

          begin
            reset_if_forked
            return false if @syncing

            current_time = now
            return false unless time_to_sync?(current_time)

            @last_sync_at = current_time
            @syncing = true
            true
          ensure
            @mutex.unlock
          end
        end

        def complete_sync
          @mutex.synchronize do
            @syncing = false
          end
        end

        def time_to_sync?(current_time)
          seconds_since_last_sync = current_time - @last_sync_at
          seconds_since_last_sync >= @interval
        end

        def reset_if_forked
          return if @pid == Process.pid

          @pid = Process.pid
          @syncing = false
        end

        def now
          Process.clock_gettime(Process::CLOCK_MONOTONIC, :second)
        end
      end
    end
  end
end
