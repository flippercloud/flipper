require "concurrent/utility/monotonic_time"
require "flipper/adapters/dual_write"
require "flipper/adapters/memory"

module Flipper
  module Cloud
    # Internal: Serves reads from a Memory adapter that every thread in the
    # process shares, so checking a feature never queries the local adapter.
    # Writes go to the local adapter, then to Memory. The sync version is the
    # local adapter's, because that is the one other processes share.
    class MemoryAdapter < Adapters::DualWrite
      # adapter - The local adapter, such as ActiveRecord.
      # memory - The shared Flipper::Adapters::Memory.
      # refresh_interval - Seconds between reloads of memory from adapter, or
      #                    nil to never reload. Webhook mode sets it, because
      #                    only the process that gets a webhook syncs it.
      def initialize(adapter, memory, refresh_interval: nil)
        super(memory, adapter)
        @refresh_interval = refresh_interval
        @refresh_at = Concurrent.monotonic_time + refresh_interval if refresh_interval
      end

      def features
        refresh
        super
      end

      def get(feature)
        refresh
        super
      end

      def get_multi(features)
        refresh
        super
      end

      def get_all(**kwargs)
        refresh
        super
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
        return unless @refresh_at

        now = Concurrent.monotonic_time
        return if now < @refresh_at

        @refresh_at = now + @refresh_interval
        # An adapter that was never synced has nothing newer than memory.
        @local.import(@remote) if @remote.sync_version
      rescue StandardError
        # Keep serving memory while the local adapter is down.
      end
    end
  end
end
