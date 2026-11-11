require "flipper/adapters/memory"

module Flipper
  module Cloud
    # Internal: The Memory adapter that every thread in a process reads from.
    # It also remembers the last Cloud version the process synced, so threads
    # skip syncing the local adapter after a poll that changed nothing.
    class SharedMemory < Adapters::Memory
      # Public: Returns true if a sync of version finished in this process.
      def synced?(version)
        !version.nil? && synchronize { @synced_version == version }
      end

      # Public: Records that a sync of version finished in this process.
      def synced(version)
        synchronize { @synced_version = version }
      end
    end
  end
end
