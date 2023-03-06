require 'flipper/adapters/sync'
require 'flipper/poller'

module Flipper
  module Adapters
    # Adapter that keeps a local and remote adapter in sync via a background poller.
    #
    # Synchronization is performed whenever the adapter is access if the background
    # poller has been synced.
    #
    #   remote_adapter = Flipper::Adapters::Http.new(url: 'http://example.com/flipper')
    #   local_adapter = Flipper::Adapters::Memory.new
    #   poller = Flipper::Poller.get('my_poller', remote_adapter: remote_adapter, interval: 5)
    #   adapter = Flipper::Adapters::Poll.new(poller, local_adapter)
    #
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
