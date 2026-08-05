require 'flipper/adapters/sync/synchronizer'
require 'flipper/poller'

module Flipper
  module Adapters
    class Poll
      extend Forwardable
      include ::Flipper::Adapter

      # Deprecated
      Poller = ::Flipper::Poller

      attr_reader :adapter, :poller

      def_delegators :synced_adapter, :features, :get, :get_multi, :get_all, :add, :remove, :clear, :enable, :disable

      def initialize(poller, adapter)
        @adapter = adapter
        @poller = poller
        @pid = Process.pid
        @last_synced_at = 0
        @syncing = false
        @sync_mutex = Mutex.new

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
        reset_sync_state_if_forked
        @poller.start
        poller_last_synced_at = @poller.last_synced_at.value
        if claim_sync(poller_last_synced_at)
          synced = false
          begin
            Flipper::Adapters::Sync::Synchronizer.new(@adapter, @poller.adapter).call
            synced = true
          ensure
            synced ? complete_sync(poller_last_synced_at) : release_sync
          end
        end
        @adapter
      end

      def reset_sync_state_if_forked
        return if @pid == Process.pid

        @pid = Process.pid
        @syncing = false
        @sync_mutex = Mutex.new
      end

      # Internal: Attempts to claim the right to sync. Returns true if this
      # caller should sync. Returns false if a sync is unnecessary or if
      # another thread is already syncing. Never blocks. Callers that lose the
      # claim serve the local adapter as is, which is at most one poll interval
      # stale, rather than waiting on a sync in the middle of a request.
      def claim_sync(poller_last_synced_at)
        @sync_mutex.synchronize do
          return false if @syncing
          return false unless poller_last_synced_at > @last_synced_at

          @syncing = true
          true
        end
      end

      def complete_sync(poller_last_synced_at)
        @sync_mutex.synchronize do
          @last_synced_at = poller_last_synced_at
          @syncing = false
        end
      end

      def release_sync
        @sync_mutex.synchronize { @syncing = false }
      end
    end
  end
end
