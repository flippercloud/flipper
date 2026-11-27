require "flipper/adapters/memory"

module Flipper
  module Cloud
    # Internal: The Memory adapter that every thread in a process reads from.
    # It also remembers the last Cloud version the process synced, so threads
    # skip syncing the local adapter after a poll that changed nothing.
    class SharedMemory < Adapters::Memory
      # Seconds a copy of the local adapter must match memory's last change
      # from one to show that no sync was still writing it.
      RECOPY_INTERVAL = 1

      def initialize(source = nil, threadsafe: true)
        super
        @syncing = Hash.new(0)
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

      # Public: Imports the local adapter again only if the last copy may have
      # caught a sync partway. Reads nothing from it otherwise.
      def recopy(store)
        import(store, recopy: true) if recopy_due?
      end

      # Public: Returns true if a sync of version finished in this process.
      def synced?(version)
        !version.nil? && synchronize { @synced_version == version }
      end

      # Public: Returns true for the first thread to ask about the poll at
      # polled_at, and false for the rest, so one thread per poll checks the
      # local adapter's version. A thread still on an older poll gets false.
      def claim_store_check(polled_at)
        synchronize do
          return false if @store_checked_at && polled_at <= @store_checked_at
          @store_checked_at = polled_at
          true
        end
      end

      # Public: Gives back a claim whose check failed, so the next thread to
      # read checks the poll at polled_at again.
      def release_store_check(polled_at)
        synchronize { @store_checked_at = nil if @store_checked_at == polled_at }
      end

      # Public: Runs the block that syncs version, then records it as synced.
      # Records nothing if the block raises or a sync of another version ran at
      # the same time, because an older sync can write its flags after a newer
      # one. The next poll then syncs again and repairs them. Threads syncing
      # the same version write the same flags, so they can still record it,
      # but one that raises may have left flags half written, so it forgets
      # the recorded version and keeps syncs still running from recording.
      def sync(version)
        alone, overlaps = synchronize do
          other_version = @syncing.any? { |syncing_version, _| syncing_version != version }
          @overlaps += 1 if other_version
          @syncing[version] += 1
          [!other_version, @overlaps]
        end
        finished = false
        yield
        finished = true
      ensure
        synchronize do
          @syncing[version] -= 1
          @syncing.delete(version) if @syncing[version] <= 0
          if finished
            @synced_version = version if alone && overlaps == @overlaps
          else
            @overlaps += 1
            @synced_version = nil
          end
        end
      end

      private

      def recopy_due?
        synchronize { @recopy && now - @changed_at >= RECOPY_INTERVAL }
      end

      def now
        Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_second)
      end
    end
  end
end
