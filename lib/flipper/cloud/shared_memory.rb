require "flipper/adapters/memory"

module Flipper
  module Cloud
    # Internal: The Memory adapter that every thread in a process reads from.
    # It also remembers the last Cloud version the process synced, so threads
    # skip syncing the local adapter after a poll that changed nothing.
    class SharedMemory < Adapters::Memory
      # Seconds a copy of the local adapter must match memory's last change
      # from one to show that no sync was still writing it.
      RECOPY_INTERVAL = 10

      def initialize(source = nil, threadsafe: true)
        super
        @syncing = 0
        @overlaps = 0
        @recopy = false
        @changed_at = 0
      end

      # Public: Imports flags. Pass recopy: true when source is the local
      # adapter, which another process may be syncing. A sync writes its
      # version before its flags, so the copy can have only some of them under
      # the new version. reload then copies again until a copy changes nothing
      # RECOPY_INTERVAL after the last one that did.
      def import(source, recopy: false)
        super(source) do |features, version|
          @changed_at = now if recopy && (version != @sync_version || features != @source)
          @recopy = recopy && now - @changed_at < RECOPY_INTERVAL
        end
      end

      # Public: Imports the local adapter if another process synced a new
      # version, or if the last copy may have caught a sync partway.
      def reload(store)
        version = store.sync_version
        return if version.nil?

        import(store, recopy: true) if version != sync_version || recopy_due?
      end

      # Public: Returns true if a sync of version finished in this process.
      def synced?(version)
        !version.nil? && synchronize { @synced_version == version }
      end

      # Public: Runs the block that syncs version, then records it as synced.
      # Records nothing if the block raises or another sync ran at the same
      # time, because an older sync can write its flags after a newer one. The
      # next poll then syncs again and repairs them.
      def sync(version)
        alone, overlaps = synchronize do
          @syncing += 1
          @overlaps += 1 if @syncing > 1
          [@syncing == 1, @overlaps]
        end
        finished = false
        yield
        finished = true
      ensure
        synchronize do
          @syncing -= 1
          @synced_version = version if finished && alone && overlaps == @overlaps
        end
      end

      private

      def recopy_due?
        synchronize { @recopy && now - @changed_at >= RECOPY_INTERVAL }
      end

      def now
        Process.clock_gettime(Process::CLOCK_MONOTONIC, :second)
      end
    end
  end
end
