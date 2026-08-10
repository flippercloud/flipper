require 'flipper/adapters/sync/synchronizer'
require 'flipper/adapters/memory'
require 'flipper/poller'
require 'concurrent/atomic/atomic_reference'

module Flipper
  module Adapters
    class Poll
      extend Forwardable
      include ::Flipper::Adapter

      SyncState = Struct.new(:pid, :mutex, :syncing, :last_synced_at, :snapshot)

      class InFlightAdapter
        extend Forwardable

        def_delegators :@snapshot, :features, :get, :get_multi, :get_all
        def_delegators :@adapter, :add, :remove, :clear, :enable, :disable

        def initialize(snapshot, adapter)
          @snapshot = snapshot
          @adapter = adapter
        end
      end

      # Deprecated
      Poller = ::Flipper::Poller

      attr_reader :adapter, :poller

      def_delegators :synced_adapter, :features, :get, :get_multi, :get_all, :add, :remove, :clear, :enable, :disable

      def initialize(poller, adapter)
        @adapter = adapter
        @poller = poller
        @sync_state = Concurrent::AtomicReference.new(
          SyncState.new(Process.pid, Mutex.new, false, 0, nil)
        )

        # If the adapter is empty, we need to sync before starting the poller.
        # Yes, this will block the main thread, but that's better than thinking
        # nothing is enabled.
        if adapter.features.empty?
          begin
            @poller.sync
          rescue
            # TODO: Warn here that it's possible that no data has been synced
            # and flags are being evaluated without flag data being present
            # until a sync completes. We rescue to avoid flipper being down
            # causing your processes to crash.
          end
        end

        @poller.start
      end

      private

      def synced_adapter
        state = sync_state
        @poller.start
        poller_last_synced_at = @poller.last_synced_at.value
        claim, value = claim_sync(state, poller_last_synced_at)
        case claim
        when :claimed
          synced = false
          begin
            Flipper::Adapters::Sync::Synchronizer.new(
              @adapter,
              @poller.adapter,
              local_get_all: value
            ).call
            synced = true
          ensure
            synced ? complete_sync(state, poller_last_synced_at) : release_sync(state)
          end
          @adapter
        when :syncing
          value
        else
          @adapter
        end
      end

      def sync_state
        pid = Process.pid
        loop do
          state = @sync_state.get
          return state if state.pid == pid

          replacement = SyncState.new(pid, Mutex.new, false, state.last_synced_at, nil)
          return replacement if @sync_state.compare_and_set(state, replacement)
        end
      end

      # Internal: Attempts to claim the right to sync. Returns the status and
      # the data captured while holding the mutex: the local state for :claimed
      # or the coherent pre-sync adapter for :syncing. Never blocks. Callers
      # that lose an in-flight claim read from the snapshot rather than waiting
      # on a sync in the middle of a request.
      def claim_sync(state, poller_last_synced_at)
        return [:contended, nil] unless state.mutex.try_lock

        begin
          return [:syncing, state.snapshot] if state.syncing
          return [:not_needed, nil] unless poller_last_synced_at > state.last_synced_at

          local_get_all = @adapter.get_all
          snapshot = Flipper::Adapters::Memory.new(local_get_all)
          state.snapshot = InFlightAdapter.new(snapshot, @adapter)
          state.syncing = true
          [:claimed, local_get_all]
        ensure
          state.mutex.unlock
        end
      end

      def complete_sync(state, poller_last_synced_at)
        state.mutex.synchronize do
          state.last_synced_at = poller_last_synced_at
          state.syncing = false
          state.snapshot = nil
        end
      end

      def release_sync(state)
        state.mutex.synchronize do
          state.syncing = false
          state.snapshot = nil
        end
      end
    end
  end
end
