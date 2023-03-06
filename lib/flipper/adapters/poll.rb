require 'flipper/adapters/sync'
require 'flipper/poller'

module Flipper
  module Adapters
    class Poll < Adapters::Sync
      # Private: Synchronizer that only runs when the poller has synced.
      class Synchronizer < Sync::Synchronizer
        def initialize(poller, local_adapter, options = {})
          super(local_adapter, poller.adapter, options)
          @poller = poller
          @last_synced_at = nil
        end

        def call
          poller_last_synced_at = @poller.last_synced_at.value
          return unless poller_last_synced_at != @last_synced_at
          super
          @last_synced_at = poller_last_synced_at
        end
      end

      # Public: The name of the adapter.
      attr_reader :name, :adapter, :poller

      def initialize(poller, local_adapter, options = {})
        synchronizer = Synchronizer.new(poller, local_adapter, options.merge(raise: false))
        super(local_adapter, poller.adapter, synchronizer: synchronizer)
        @name = :poll
      end
    end
  end
end
