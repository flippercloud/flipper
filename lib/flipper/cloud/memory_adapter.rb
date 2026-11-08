require "concurrent/utility/monotonic_time"
require "flipper/adapters/memory"

module Flipper
  module Cloud
    # Internal: Serves reads from a Memory adapter that every thread in the
    # process shares, so checking a feature never queries the local adapter.
    # Writes go to the local adapter, then to Memory. The sync version is the
    # local adapter's, because that is the one other processes share.
    class MemoryAdapter
      include ::Flipper::Adapter

      attr_reader :adapter, :memory

      # adapter - The local adapter, such as ActiveRecord.
      # memory - The shared Flipper::Adapters::Memory.
      # refresh_interval - Seconds between reloads of memory from adapter, or
      #                    nil to never reload. Webhook mode sets it, because
      #                    only the process that gets a webhook syncs it.
      def initialize(adapter, memory, refresh_interval: nil)
        @adapter = adapter
        @memory = memory
        @refresh_interval = refresh_interval
        @refresh_at = Concurrent.monotonic_time + refresh_interval if refresh_interval
      end

      def features
        refresh if @refresh_interval
        @memory.features
      end

      def get(feature)
        refresh if @refresh_interval
        @memory.get(feature)
      end

      def get_multi(features)
        refresh if @refresh_interval
        @memory.get_multi(features)
      end

      def get_all(**kwargs)
        refresh if @refresh_interval
        @memory.get_all(**kwargs)
      end

      def sync_version
        @adapter.sync_version
      end

      def sync_version=(version)
        @adapter.sync_version = version
        @memory.sync_version = version
      end

      def add(feature)
        @adapter.add(feature).tap { @memory.add(feature) }
      end

      def remove(feature)
        @adapter.remove(feature).tap { @memory.remove(feature) }
      end

      def clear(feature)
        @adapter.clear(feature).tap { @memory.clear(feature) }
      end

      def enable(feature, gate, thing)
        @adapter.enable(feature, gate, thing).tap { @memory.enable(feature, gate, thing) }
      end

      def disable(feature, gate, thing)
        @adapter.disable(feature, gate, thing).tap { @memory.disable(feature, gate, thing) }
      end

      private

      def refresh
        now = Concurrent.monotonic_time
        return if now < @refresh_at

        @refresh_at = now + @refresh_interval
        @memory.import(@adapter)
      rescue StandardError
        # Keep serving memory while the local adapter is down.
      end
    end
  end
end
