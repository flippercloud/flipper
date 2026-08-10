require 'flipper/adapters/sync/synchronizer'
require 'flipper/adapters/memory'
require 'flipper/poller'
require 'concurrent/atomic/atomic_reference'

module Flipper
  module Adapters
    class Poll
      extend Forwardable
      include ::Flipper::Adapter

      SyncState = Struct.new(:pid, :mutex, :syncing, :last_synced_at, :snapshot, :sync_failed)

      class InFlightAdapter
        extend Forwardable

        def_delegators :@snapshot, :features, :get, :get_multi, :get_all
        def_delegators :@adapter, :add, :remove, :clear, :enable, :disable

        def initialize(snapshot, adapter)
          @snapshot = snapshot
          @adapter = adapter
        end
      end

      class PendingSnapshotAdapter
        extend Forwardable

        def_delegators :read_adapter, :features, :get, :get_multi, :get_all
        def_delegators :@adapter, :add, :remove, :clear, :enable, :disable

        def initialize(state, adapter)
          @state = state
          @adapter = adapter
        end

        private

        def read_adapter
          @state.snapshot || @adapter
        end
      end

      # Deprecated
      Poller = ::Flipper::Poller

      attr_reader :adapter, :poller

      def_delegators :synced_adapter, :features, :get, :get_multi, :get_all, :add, :remove, :clear, :enable, :disable

      def initialize(poller, adapter)
        @adapter = adapter
        @poller = poller
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

        snapshot = begin
          InFlightAdapter.new(Flipper::Adapters::Memory.new(adapter.get_all), adapter)
        rescue
          # Preserve the existing fail-open initialization behavior. The first
          # successful request establishes the snapshot before a sync can run.
        end
        @sync_state = Concurrent::AtomicReference.new(
          SyncState.new(Process.pid, Mutex.new, false, 0, snapshot, false)
        )

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
          completed_snapshot = nil
          begin
            Flipper::Adapters::Sync::Synchronizer.new(
              @adapter,
              @poller.adapter,
              local_get_all: value
            ).call
            begin
              completed_snapshot = InFlightAdapter.new(
                Flipper::Adapters::Memory.new(@adapter.get_all),
                @adapter
              )
            rescue
              # The adapter is synchronized, but its completed state could not
              # be captured. Keep serving the previous trusted snapshot to
              # contenders and retry publication on the next request.
            end
          ensure
            if completed_snapshot
              complete_sync(state, poller_last_synced_at, completed_snapshot)
            else
              release_sync(state)
            end
          end
          @adapter
        when :syncing, :contended, :snapshot_established
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

          replacement = SyncState.new(
            pid,
            Mutex.new,
            false,
            state.last_synced_at,
            state.snapshot,
            state.sync_failed
          )
          return replacement if @sync_state.compare_and_set(state, replacement)
        end
      end

      # Internal: Attempts to claim the right to sync. Returns the status and
      # the data associated with that status: the local state for :claimed or
      # the latest coherent adapter for all other read statuses. Never blocks.
      # Callers that lose an in-flight claim read from the snapshot rather than
      # waiting on a sync in the middle of a request.
      def claim_sync(state, poller_last_synced_at)
        unless state.mutex.try_lock
          adapter = state.snapshot || PendingSnapshotAdapter.new(state, @adapter)
          return [:contended, adapter]
        end

        begin
          return [:syncing, state.snapshot] if state.syncing
          unless state.snapshot
            local_get_all = @adapter.get_all
            snapshot = Flipper::Adapters::Memory.new(local_get_all)
            established_snapshot = InFlightAdapter.new(snapshot, @adapter)
            state.snapshot = established_snapshot
            return [:snapshot_established, established_snapshot]
          end
          return [:not_needed, nil] unless poller_last_synced_at > state.last_synced_at

          local_get_all = @adapter.get_all
          unless state.sync_failed
            snapshot = Flipper::Adapters::Memory.new(local_get_all)
            state.snapshot = InFlightAdapter.new(snapshot, @adapter)
          end
          state.syncing = true
          [:claimed, local_get_all]
        ensure
          state.mutex.unlock
        end
      end

      def complete_sync(state, poller_last_synced_at, completed_snapshot)
        state.mutex.synchronize do
          state.last_synced_at = poller_last_synced_at
          state.snapshot = completed_snapshot
          state.sync_failed = false
          state.syncing = false
        end
      end

      def release_sync(state)
        state.mutex.synchronize do
          state.sync_failed = true
          state.syncing = false
        end
      end
    end
  end
end
