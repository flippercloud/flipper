require "flipper/instrumenters/noop"

module Flipper
  module Adapters
    # TODO: Syncing should happen in a background thread on a regular interval
    # rather than in the main thread only when reads happen.
    class Sync
      include ::Flipper::Adapter

      # Public: The name of the adapter.
      attr_reader :name

      # Public: Build a new sync instance.
      #
      # local - The local flipper adapter that should serve reads.
      # remote - The remote flipper adpater that should serve writes and update
      #          the local on an interval.
      # interval - The number of milliseconds between syncs from remote to
      #            local. Default value is set in IntervalSynchronizer.
      def initialize(local, remote, options = {})
        @name = :sync
        @local = local
        @remote = remote
        @synchronizer = options.fetch(:synchronizer) do
          instrumenter = options[:instrumenter]
          sync_options = {}
          sync_options[:instrumenter] = instrumenter if instrumenter
          synchronizer = Synchronizer.new(@local, @remote, sync_options)
          IntervalSynchronizer.new(synchronizer, interval: options[:interval])
        end
        sync
      end

      def features
        sync
        @local.features
      end

      def get(feature)
        sync
        @local.get(feature)
      end

      def get_multi(features)
        sync
        @local.get_multi(features)
      end

      def get_all
        sync
        @local.get_all
      end

      def add(feature)
        result = @remote.add(feature)
        @local.add(feature)
        result
      end

      def remove(feature)
        result = @remote.remove(feature)
        @local.remove(feature)
        result
      end

      def clear(feature)
        result = @remote.clear(feature)
        @local.clear(feature)
        result
      end

      def enable(feature, gate, thing)
        result = @remote.enable(feature, gate, thing)
        @local.enable(feature, gate, thing)
        result
      end

      def disable(feature, gate, thing)
        result = @remote.disable(feature, gate, thing)
        @local.disable(feature, gate, thing)
        result
      end

      private

      def sync
        @synchronizer.call
      end

      class IntervalSynchronizer
        # Private: Default to syncing every 10 seconds.
        DEFAULT_INTERVAL_MS = 10_000

        def initialize(synchronizer, interval: nil)
          @synchronizer = synchronizer
          @interval = interval || DEFAULT_INTERVAL_MS
          @last_sync_at = 0
        end

        def call
          return unless time_to_sync?

          @last_sync_at = now_ms
          @synchronizer.call

          nil
        end

        private

        def time_to_sync?
          (now_ms - @last_sync_at) >= @interval
        end

        def now_ms
          Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
        end
      end

      class Synchronizer
        def initialize(local, remote, options = {})
          @local = local
          @remote = remote
          @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
        end

        def call
          local_get_all = @local.get_all
          remote_get_all = @remote.get_all

          # Sync all the gate values.
          remote_get_all.each do |feature_key, remote_gates_hash|
            feature = Feature.new(feature_key, @local)
            local_gates_hash = local_get_all[feature_key] || @local.default_config
            local_gate_values = GateValues.new(local_gates_hash)
            remote_gate_values = GateValues.new(remote_gates_hash)
            FeatureSynchronizer.new(feature, local_gate_values, remote_gate_values).call
          end

          # Add features that are missing
          features_to_add = remote_get_all.keys - local_get_all.keys
          features_to_add.each do |feature_key|
            Feature.new(feature_key, @local).add
          end
        rescue => exception
          payload = {
            exception: exception,
          }
          @instrumenter.instrument("synchronizer_exception.flipper", payload)
        end
      end

      class FeatureSynchronizer
        extend Forwardable

        def_delegator :@local_gate_values, :boolean, :local_boolean
        def_delegator :@local_gate_values, :actors, :local_actors
        def_delegator :@local_gate_values, :groups, :local_groups
        def_delegator :@local_gate_values, :percentage_of_actors,
                      :local_percentage_of_actors
        def_delegator :@local_gate_values, :percentage_of_time,
                      :local_percentage_of_time

        def_delegator :@remote_gate_values, :boolean, :remote_boolean
        def_delegator :@remote_gate_values, :actors, :remote_actors
        def_delegator :@remote_gate_values, :groups, :remote_groups
        def_delegator :@remote_gate_values, :percentage_of_actors,
                      :remote_percentage_of_actors
        def_delegator :@remote_gate_values, :percentage_of_time,
                      :remote_percentage_of_time

        def initialize(feature, local_gate_values, remote_gate_values)
          @feature = feature
          @local_gate_values = local_gate_values
          @remote_gate_values = remote_gate_values
        end

        def call
          if remote_disabled?
            return if local_disabled?
            @feature.disable
          elsif remote_boolean_enabled?
            return if local_boolean_enabled?
            @feature.enable
          else
            sync_actors
            sync_groups
            sync_percentage_of_actors
            sync_percentage_of_time
          end
        end

        private

        def sync_actors
          remote_actors_added = remote_actors - local_actors
          remote_actors_added.each do |flipper_id|
            @feature.enable_actor Actor.new(flipper_id)
          end

          remote_actors_removed = local_actors - remote_actors
          remote_actors_removed.each do |flipper_id|
            @feature.disable_actor Actor.new(flipper_id)
          end
        end

        def sync_groups
          remote_groups_added = remote_groups - local_groups
          remote_groups_added.each do |group_name|
            @feature.enable_group group_name
          end

          remote_groups_removed = local_groups - remote_groups
          remote_groups_removed.each do |group_name|
            @feature.disable_group group_name
          end
        end

        def sync_percentage_of_actors
          return if local_percentage_of_actors == remote_percentage_of_actors

          @feature.enable_percentage_of_actors remote_percentage_of_actors
        end

        def sync_percentage_of_time
          return if local_percentage_of_time == remote_percentage_of_time

          @feature.enable_percentage_of_time remote_percentage_of_time
        end

        def default_config
          @default_config ||= @feature.adapter.default_config
        end

        def default_gate_values
          @default_gate_values ||= GateValues.new(default_config)
        end

        def default_gate_values?(gate_values)
          gate_values == default_gate_values
        end

        def local_disabled?
          default_gate_values? @local_gate_values
        end

        def remote_disabled?
          default_gate_values? @remote_gate_values
        end

        def local_boolean_enabled?
          local_boolean
        end

        def remote_boolean_enabled?
          remote_boolean
        end
      end
    end
  end
end
