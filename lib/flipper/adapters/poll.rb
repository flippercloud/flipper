require 'concurrent/atomic/atomic_fixnum'
require 'flipper/poller'

module Flipper
  module Adapters
    # An adapter that keeps a local memory adapter in sync with a source adapter
    # via a background poller thread.
    #
    # Reads go to the local memory adapter (fast, zero-impact).
    # Writes go to the source adapter first, then update the local memory adapter.
    # A background thread periodically polls the source adapter and updates the
    # local memory adapter so other processes' writes are picked up.
    class Poll
      include ::Flipper::Adapter

      SYNC_KEY = :flipper_poll_sync_suppressed

      # Public: The Poller instance used to sync in the background.
      attr_reader :poller

      # Public: The local memory adapter that serves reads.
      attr_reader :local

      # Public: The source adapter that receives writes and is polled.
      attr_reader :remote

      # Public: Build a new Poll adapter.
      #
      # source - The source adapter to poll and write to (e.g., ActiveRecord, Redis).
      # options - The Hash of options:
      #           :key    - The key to identify the poller instance (default: object_id).
      #           :interval - Poll interval in seconds (default: 10).
      #           :instrumenter - Instrumenter for events (default: Noop).
      #           :start_automatically - Start the poller thread automatically (default: true).
      #           :shutdown_automatically - Register at_exit handler (default: true).
      def initialize(source, options = {})
        key = options.fetch(:key, object_id.to_s)
        poller_options = {
          remote_adapter: source,
          interval: options.fetch(:interval, 10),
          instrumenter: options.fetch(:instrumenter, Instrumenters::Noop),
          start_automatically: options.fetch(:start_automatically, true),
          shutdown_automatically: options.fetch(:shutdown_automatically, true),
        }
        @poller = Flipper::Poller.get(key, poller_options)
        @local = Adapters::Memory.new
        @remote = source
        @last_synced_at = Concurrent::AtomicFixnum.new(0)

        # Block the main thread for the initial sync so we don't serve
        # empty/default values before the first poll completes.
        begin
          @poller.sync
          sync
        rescue
          # Rescue to avoid source adapter being down causing processes to crash.
        end
      end

      def adapter_stack
        "poll(local: #{@local.adapter_stack}, remote: #{@remote.adapter_stack})"
      end

      # Public: Synchronize the local memory adapter with the poller's latest
      # snapshot if the poller has synced since we last checked.
      #
      # If given a block, syncs once at the start and suppresses further syncs
      # for the duration of the block (useful for per-request sync).
      def sync
        poller_last_synced_at = @poller.last_synced_at.value
        last = @last_synced_at.value
        if poller_last_synced_at > last
          @local.import(@poller.adapter)
          @last_synced_at.update { poller_last_synced_at }
        end

        if block_given?
          begin
            Thread.current[SYNC_KEY] = true
            yield
          ensure
            Thread.current[SYNC_KEY] = false
          end
        end
      end

      # Reads - always from local memory

      def features
        maybe_sync
        @local.features
      end

      def get(feature)
        maybe_sync
        @local.get(feature)
      end

      def get_multi(features)
        maybe_sync
        @local.get_multi(features)
      end

      def get_all(**kwargs)
        maybe_sync
        @local.get_all(**kwargs)
      end

      # Writes - go to source first, then update local memory

      def add(feature)
        @remote.add(feature).tap { @local.add(feature) }
      end

      def remove(feature)
        @remote.remove(feature).tap { @local.remove(feature) }
      end

      def clear(feature)
        @remote.clear(feature).tap { @local.clear(feature) }
      end

      def enable(feature, gate, thing)
        @remote.enable(feature, gate, thing).tap do
          @local.enable(feature, gate, thing)
        end
      end

      def disable(feature, gate, thing)
        @remote.disable(feature, gate, thing).tap do
          @local.disable(feature, gate, thing)
        end
      end

      private

      def maybe_sync
        sync unless Thread.current[SYNC_KEY]
      end
    end
  end
end
