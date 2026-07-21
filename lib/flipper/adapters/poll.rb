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
        @sync_condition = ConditionVariable.new

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
        @sync_condition = ConditionVariable.new
      end

      def claim_sync(poller_last_synced_at)
        @sync_mutex.synchronize do
          loop do
            return false unless poller_last_synced_at > @last_synced_at

            unless @syncing
              @syncing = true
              return true
            end

            @sync_condition.wait(@sync_mutex)
          end
        end
      end

      def complete_sync(poller_last_synced_at)
        @sync_mutex.synchronize do
          @last_synced_at = poller_last_synced_at
          @syncing = false
          @sync_condition.broadcast
        end
      end

      def release_sync
        @sync_mutex.synchronize do
          @syncing = false
          @sync_condition.broadcast
        end
      end
    end
  end
end
