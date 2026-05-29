require "flipper/feature"
require "flipper/gate_values"
require "flipper/adapters/actor_limit"
require "flipper/adapters/strict"
require "flipper/adapters/sync/feature_synchronizer"

module Flipper
  module Adapters
    class Sync
      # Public: Given a local and remote adapter, it can update the local to
      # match the remote doing only the necessary enable/disable operations.
      class Synchronizer
        SYNC_VERSION_KEY = :sync_version
        MAX_OUTVOTE_REPAIRS = 3

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
          remote_get_all = remote_snapshot.features
          remote_version = remote_snapshot.version
          local_version = @local.read_integer(SYNC_VERSION_KEY)

          if remote_version && local_version && remote_version.to_i <= local_version.to_i
            return
          end

          apply(remote_get_all)

          if remote_version
            accepted = @local.set_integer_if_greater(SYNC_VERSION_KEY, remote_version)
            # A rejection only indicates an outvote when the local adapter actually
            # stores a higher version. Adapters without typed-integer storage return
            # false unconditionally, so guard on the post-write read to keep the
            # event and repair scoped to real races (including cold-start interleaves
            # where local_version was nil pre-sync).
            current_version = @local.read_integer(SYNC_VERSION_KEY)
            if !accepted && current_version && current_version.to_i > remote_version.to_i
              @instrumenter.instrument("synchronizer_outvoted.flipper", remote_version: remote_version)
              repair_after_outvote(remote_version)
            end
          end

          nil
        rescue => exception
          @instrumenter.instrument("synchronizer_exception.flipper", exception: exception)
          raise if @raise
        end

        def apply(remote_get_all)
          local_get_all = @local.get_all

          # Sync all the gate values.
          remote_get_all.each do |feature_key, remote_gates_hash|
            feature = Feature.new(feature_key, @local, instrumenter: @instrumenter)
            # Check if feature_key is in hash before accessing to prevent unintended hash modification
            local_gates_hash = local_get_all.key?(feature_key) ? local_get_all[feature_key] : @local.default_config
            local_gate_values = GateValues.new(local_gates_hash)
            remote_gate_values = GateValues.new(remote_gates_hash)
            FeatureSynchronizer.new(feature, local_gate_values, remote_gate_values).call
          end

          # Add features that are missing in local and present in remote.
          features_to_add = remote_get_all.keys - local_get_all.keys
          features_to_add.each { |key| Feature.new(key, @local, instrumenter: @instrumenter).add }

          # Remove features that are present in local and missing in remote.
          features_to_remove = local_get_all.keys - remote_get_all.keys
          features_to_remove.each { |key| Feature.new(key, @local, instrumenter: @instrumenter).remove }
        end

        def repair_after_outvote(outvoted_version)
          current_version = @local.read_integer(SYNC_VERSION_KEY)
          return unless current_version && current_version.to_i > outvoted_version.to_i

          MAX_OUTVOTE_REPAIRS.times do
            remote_snapshot = @remote.get_all_snapshot(cache_bust: true)
            apply(remote_snapshot.features)

            @local.set_integer_if_greater(SYNC_VERSION_KEY, remote_snapshot.version) if remote_snapshot.version

            current_version = @local.read_integer(SYNC_VERSION_KEY)
            break unless remote_snapshot.version && current_version && current_version.to_i > remote_snapshot.version.to_i
          end
        end
      end
    end
  end
end
