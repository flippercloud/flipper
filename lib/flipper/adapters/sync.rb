require "flipper/adapters/dual_write"
require "flipper/adapters/sync/synchronizer"
require "flipper/adapters/sync/interval_synchronizer"

module Flipper
  module Adapters
    # Adapter that periodically keeps a local and remote adapter in sync.
    #
    # Synchronization is performed on an interval in the current thread whenever
    # the adapter is accessed. Use `Flipper::Adapters::Poll` if you want to
    # perform synchronization in a background thread.
    class Sync
      extend Forwardable
      include ::Flipper::Adapter

      # Public: The name of the adapter.
      attr_reader :name

      # Public: The synchronizer that will keep the local and remote in sync.
      attr_reader :synchronizer

      def_delegators :synced_adapter, :features, :get, :get_multi, :get_all, :add, :remove, :clear, :enable, :disable

      # Public: Build a new sync instance.
      #
      # local - The local flipper adapter that should serve reads.
      # remote - The remote flipper adapter that should serve writes and update
      #          the local on an interval.
      # interval - The Float or Integer number of seconds between syncs from
      # remote to local. Default value is set in IntervalSynchronizer.
      def initialize(local, remote, options = {})
        @name = :sync
        @adapter = DualWrite.new(local, remote)
        @synchronizer = options.fetch(:synchronizer) do
          sync_options = {
            raise: false,
          }
          instrumenter = options[:instrumenter]
          sync_options[:instrumenter] = instrumenter if instrumenter
          synchronizer = Synchronizer.new(local, remote, sync_options)
          IntervalSynchronizer.new(synchronizer, interval: options[:interval])
        end
      end

      private

      def synced_adapter
        @synchronizer.call
        @adapter
      end
    end
  end
end
