require 'flipper/adapters/sync/synchronizer'

module Flipper
  module Adapters
    class Poll
      extend Forwardable
      include ::Flipper::Adapter

      # Public: The name of the adapter.
      attr_reader :name, :adapter, :poller

      def_delegators :synced_adapter, :features, :get, :get_multi, :get_all, :add, :remove, :clear, :enable, :disable

      def initialize(poller, adapter)
        @name = :poll
        @adapter = adapter
        @poller = poller
        @last_synced_at = 0
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
