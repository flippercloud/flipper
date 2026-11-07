require "flipper/feature"
require "flipper/gate_values"
require "flipper/adapters/actor_limit"
require "flipper/adapters/strict"
require "flipper/adapters/sync/snapshot_applier"

module Flipper
  module Adapters
    class Sync
      # Public: Given a local and remote adapter, it can update the local to
      # match the remote doing only the necessary enable/disable operations.
      class Synchronizer
        # Public: Initializes a new synchronizer.
        #
        # local - The Flipper adapter to get in sync with the remote.
        # remote - The Flipper adapter that is source of truth that the local
        #          adapter should be brought in line with.
        # options - The Hash of options.
        #           :instrumenter - The instrumenter used to instrument.
        #           :raise - Should errors be raised (default: true).
        #           :cache_bust - Should cache busting be used for remote get_all (default: false).
        def initialize(local, remote, options = {})
          @local = local
          @remote = remote
          @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
          @raise = options.fetch(:raise, true)
          @cache_bust = options.fetch(:cache_bust, false)
        end

        # Public: Forces a sync.
        def call
          @instrumenter.instrument("synchronizer_call.flipper") do
            Flipper::Adapters::Strict.with_sync_mode do
              Flipper::Adapters::ActorLimit.with_sync_mode { sync }
            end
          end
        end

        private

        def sync
          remote_snapshot = @remote.get_all_snapshot(cache_bust: @cache_bust)
          if @local.supports?(:atomic_snapshot_install)
            @local.apply_snapshot(remote_snapshot, instrumenter: @instrumenter)
          else
            SnapshotApplier.new(@local, remote_snapshot.features, instrumenter: @instrumenter).call
          end

          nil
        rescue => exception
          @instrumenter.instrument("synchronizer_exception.flipper", exception: exception)
          raise if @raise
        end

      end
    end
  end
end
