require "flipper/adapters/memory"

module Flipper
  module Cloud
    # Internal: The Memory adapter that every thread in a process reads from.
    # It also remembers the last Cloud version the process synced, so threads
    # skip syncing the local adapter after a poll that changed nothing.
    class SharedMemory < Adapters::Memory
      def initialize(source = nil, threadsafe: true)
        super
        @syncing = 0
        @overlaps = 0
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
    end
  end
end
