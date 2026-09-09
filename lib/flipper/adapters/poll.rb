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

      def initialize(poller, adapter, options = {})
        @adapter = adapter
        @poller = poller
        @state = options[:state]
        @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
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
        if @state
          return @adapter unless @state.lock.try_enter
        end

        begin
          synchronize
        ensure
          @state.lock.exit if @state
        end
        @adapter
      end

      def synchronize
        if @state&.last_poll_failed_at
          elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - @state.last_poll_failed_at
          return if elapsed < @poller.interval
        end

        poller_last_synced_at = @poller.last_synced_at.value
        last_synced_at = @state ? @state.last_poll_at : @last_synced_at
        if poller_last_synced_at > last_synced_at
          begin
            Flipper::Adapters::Sync::Synchronizer.new(@adapter, @poller.adapter, instrumenter: @instrumenter).call
          rescue StandardError
            raise unless @state

            # Keep the snapshot pending, but share the retry limit across callers.
            # Explicit adapter writes happen outside this rescue and still raise.
            @state.last_poll_failed_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            return
          end
          if @state
            @state.last_poll_at = poller_last_synced_at
            @state.last_poll_failed_at = nil
          else
            @last_synced_at = poller_last_synced_at
          end
        end
      end
    end
  end
end
