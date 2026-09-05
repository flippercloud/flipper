require "monitor"

module Flipper
  module Adapters
    class Sync
      # Internal: Wraps a Synchronizer instance and only invokes it every
      # N seconds.
      class IntervalSynchronizer
        class State
          attr_accessor :last_poll_at, :last_sync_at
          attr_reader :lock

          def initialize(synced: false)
            @lock = Monitor.new
            @last_poll_at = 0
            @poll_generation = 0
            @last_sync_at = synced ? now : nil
          end

          def synced?
            !@last_sync_at.nil?
          end

          def poll_started
            @lock.synchronize { @poll_generation += 1 }
          end

          def synchronize_write
            @lock.synchronize do
              consume_pending_polls
              yield
            end
          end

          def consume_pending_polls
            @last_poll_at = @poll_generation
          end

          private

          def now
            Process.clock_gettime(Process::CLOCK_MONOTONIC, :second)
          end
        end

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
        def initialize(synchronizer, interval: nil, state: nil)
          @synchronizer = synchronizer
          @interval = interval || DEFAULT_INTERVAL
          @state = state || State.new
          # TODO: add jitter to this so all processes booting at the same time
          # don't phone home at the same time.
        end

        def call
          return unless time_to_sync?
          unless @state.lock.try_enter
            @state.lock.synchronize {} unless @state.synced?
            return
          end

          begin
            return unless time_to_sync?

            @synchronizer.call
            @state.last_sync_at = now
            nil
          ensure
            @state.lock.exit
          end
        end

        private

        def time_to_sync?
          return true unless @state.synced?

          seconds_since_last_sync = now - @state.last_sync_at
          seconds_since_last_sync >= @interval
        end

        def now
          Process.clock_gettime(Process::CLOCK_MONOTONIC, :second)
        end
      end
    end
  end
end
