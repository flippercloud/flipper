require "flipper/adapters/memory"
require "flipper/adapters/sync"
require "flipper/cloud/shared_memory"

module Flipper
  module Cloud
    # Internal: Serves reads from a Memory adapter that every thread in the
    # process shares, so checking a feature never queries the local adapter.
    # Writes go to the local adapter, then to Memory. The sync version is the
    # local adapter's, because that is the one other processes share.
    class MemoryAdapter < Adapters::Sync
      # adapter - The local adapter, such as ActiveRecord.
      # memory - The Flipper::Cloud::SharedMemory.
      # refresh_interval - Seconds between reloads of memory from adapter, or
      #                    nil to only copy adapter again after a copy that may
      #                    have caught a sync partway. Webhook mode sets it,
      #                    because only the process that gets a webhook syncs it.
      def initialize(adapter, memory, refresh_interval: nil)
        @reload = !refresh_interval.nil?
        synchronizer = Adapters::Sync::IntervalSynchronizer.new(method(:refresh),
          interval: refresh_interval || SharedMemory::RECOPY_INTERVAL)
        super(memory, adapter, synchronizer: synchronizer)
      end

      def sync_version
        @remote.sync_version
      end

      def sync_version=(version)
        @remote.sync_version = version
        @local.sync_version = version
      end

      private

      def refresh
        @reload ? @local.reload(@remote) : @local.recopy(@remote)
      rescue StandardError
        # Keep serving memory while the local adapter is down.
      end
    end
  end
end
