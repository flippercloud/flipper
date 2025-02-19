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
        @last_synced_at = 0

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
        @poller.start
        poller_last_synced_at = @poller.last_synced_at.value
        if poller_last_synced_at > @last_synced_at
          Flipper::Adapters::Sync::Synchronizer.new(@adapter, @poller.adapter).call
          @last_synced_at = poller_last_synced_at
        end
        @adapter
      end
    end
  end
end
