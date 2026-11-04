require 'flipper/adapters/sync/synchronizer'
require 'flipper/adapters/memory'
require 'flipper/poller'

module Flipper
  module Adapters
    class Poll
      extend Forwardable
      include ::Flipper::Adapter

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

        def initialize(snapshot, adapter)
          @snapshot = snapshot
          @adapter = adapter
        end

        private

        def read_adapter
          @snapshot.call || @adapter
        end
      end

      # Deprecated
      Poller = ::Flipper::Poller

      attr_reader :adapter, :poller

      def_delegators :synced_adapter, :features, :get, :get_multi, :get_all, :add, :remove, :clear, :enable, :disable

      def initialize(poller, adapter)
        @adapter = adapter
        @poller = poller
        @mutex = Mutex.new
        @pid = Process.pid
        @syncing = false
        @last_synced_at = 0
        @sync_failed = false
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
          build_snapshot(adapter.get_all)
        rescue
          # Preserve the existing fail-open initialization behavior. The first
          # successful request establishes the snapshot before a sync can run.
        end
        @snapshot = snapshot

        @poller.start
      end

      private

      def synced_adapter
        @poller.start
        poller_last_synced_at = @poller.last_synced_at.value
        claim, value = claim_sync(poller_last_synced_at)
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
              completed_snapshot = build_snapshot(@adapter.get_all)
            rescue
              # The adapter is synchronized, but its completed state could not
              # be captured. Keep serving the previous trusted snapshot to
              # contenders and retry publication on the next request.
            end
          ensure
            if completed_snapshot
              complete_sync(poller_last_synced_at, completed_snapshot)
            else
              release_sync
            end
          end
          @adapter
        when :syncing, :contended, :snapshot_established
          value
        else
          @adapter
        end
      end

      # Internal: Attempts to claim the right to sync. Returns the status and
      # the data associated with that status: the local state for :claimed or
      # the latest coherent adapter for all other read statuses. Never blocks.
      # Callers that lose an in-flight claim read from the snapshot rather than
      # waiting on a sync in the middle of a request.
      def claim_sync(poller_last_synced_at)
        unless @mutex.try_lock
          adapter = @snapshot || PendingSnapshotAdapter.new(-> { @snapshot }, @adapter)
          return [:contended, adapter]
        end

        begin
          reset_if_forked
          return [:syncing, @snapshot] if @syncing
          unless @snapshot
            local_get_all = @adapter.get_all
            established_snapshot = build_snapshot(local_get_all)
            @snapshot = established_snapshot
            return [:snapshot_established, established_snapshot]
          end
          return [:not_needed, nil] unless poller_last_synced_at > @last_synced_at

          local_get_all = @adapter.get_all
          unless @sync_failed
            @snapshot = build_snapshot(local_get_all)
          end
          @syncing = true
          [:claimed, local_get_all]
        ensure
          @mutex.unlock
        end
      end

      def complete_sync(poller_last_synced_at, completed_snapshot)
        @mutex.synchronize do
          @last_synced_at = poller_last_synced_at
          @snapshot = completed_snapshot
          @sync_failed = false
          @syncing = false
        end
      end

      def build_snapshot(local_get_all)
        snapshot = Flipper::Adapters::Memory.new(snapshot_copy(local_get_all))
        InFlightAdapter.new(snapshot, @adapter)
      end

      def snapshot_copy(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, nested_value), copy|
            copy[key] = snapshot_copy(nested_value)
          end
        when Set
          Set.new(value.map { |nested_value| snapshot_copy(nested_value) })
        when Array
          value.map { |nested_value| snapshot_copy(nested_value) }
        when String
          value.dup
        else
          value
        end
      end

      def release_sync
        @mutex.synchronize do
          @sync_failed = true
          @syncing = false
        end
      end

      def reset_if_forked
        return if @pid == Process.pid

        @pid = Process.pid
        if @syncing
          @syncing = false
          @sync_failed = true
        end
      end
    end
  end
end
