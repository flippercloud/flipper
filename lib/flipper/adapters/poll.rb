require 'flipper/adapters/sync/synchronizer'
require 'flipper/poller'

module Flipper
  module Adapters
    class Poll
      include ::Flipper::Adapter

      # Deprecated
      Poller = ::Flipper::Poller

      attr_reader :adapter, :poller

      def initialize(poller, adapter)
        @adapter = adapter
        @poller = poller
        @last_synced_at = 0
        # Flipper::Poller has a lock-free synced_at. Other pollers may only
        # have last_synced_at.
        @poller_has_synced_at = poller.respond_to?(:synced_at)

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

      # Written out rather than delegated so hot reads don't allocate args.
      def features
        synced_adapter.features
      end

      def get(feature)
        synced_adapter.get(feature)
      end

      def get_multi(features)
        synced_adapter.get_multi(features)
      end

      def get_all(**kwargs)
        synced_adapter.get_all(**kwargs)
      end

      def add(feature)
        synced_adapter.add(feature)
      end

      def remove(feature)
        synced_adapter.remove(feature)
      end

      def clear(feature)
        synced_adapter.clear(feature)
      end

      def enable(feature, gate, thing)
        synced_adapter.enable(feature, gate, thing)
      end

      def disable(feature, gate, thing)
        synced_adapter.disable(feature, gate, thing)
      end

      private

      def synced_adapter
        @poller.start
        poller_last_synced_at = @poller_has_synced_at ? @poller.synced_at : @poller.last_synced_at.value
        if poller_last_synced_at > @last_synced_at
          Flipper::Adapters::Sync::Synchronizer.new(@adapter, @poller.adapter).call
          @last_synced_at = poller_last_synced_at
        end
        @adapter
      end
    end
  end
end
