require 'concurrent/atomic/atomic_reference'

module Flipper
  module Adapters
    class Sync
      # Internal: Wraps a Synchronizer instance and only invokes it every
      # N seconds.
      class IntervalSynchronizer
        SyncState = Struct.new(:pid, :mutex, :syncing, :last_sync_at)

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
          @sync_state = Concurrent::AtomicReference.new(
            SyncState.new(Process.pid, Mutex.new, false, 0)
          )
        end

        def call
          state = sync_state
          return unless sync_needed?(state)

          begin
            @synchronizer.call
          ensure
            complete_sync(state)
          end

          nil
        end

        private

        def sync_state
          pid = Process.pid
          loop do
            state = @sync_state.get
            return state if state.pid == pid

            replacement = SyncState.new(pid, Mutex.new, false, state.last_sync_at)
            return replacement if @sync_state.compare_and_set(state, replacement)
          end
        end

        def sync_needed?(state)
          state.mutex.synchronize do
            current_time = now
            return false unless time_to_sync?(state, current_time)
            return false if state.syncing

            state.last_sync_at = current_time
            state.syncing = true
            true
          end
        end

        def complete_sync(state)
          state.mutex.synchronize do
            state.syncing = false
          end
        end

        def time_to_sync?(state, current_time)
          seconds_since_last_sync = current_time - state.last_sync_at
          seconds_since_last_sync >= @interval
        end

        def now
          Process.clock_gettime(Process::CLOCK_MONOTONIC, :second)
        end
      end
    end
  end
end
