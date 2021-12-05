require "flipper/actor"
require "flipper/gate_values"
require "flipper/adapters/sync/operation"

module Flipper
  module Adapters
    class Sync
      class FeatureDiff
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

        attr_reader :operations

        def initialize(feature, local_gate_values, remote_gate_values)
          @feature = feature
          @local_gate_values = local_gate_values
          @remote_gate_values = remote_gate_values
          @operations = []

          if remote_disabled?
            return if local_disabled?
            @operations << Operation.new(@feature, :disable)
          elsif remote_boolean_enabled?
            return if local_boolean_enabled?
            @operations << Operation.new(@feature, :enable)
          else
            if local_boolean_enabled?
              @operations << Operation.new(@feature, :disable)
            end

            diff_actors
            diff_groups
            diff_percentage_of_actors
            diff_percentage_of_time
          end
        end

        private

        def diff_actors
          remote_actors_added = remote_actors - local_actors
          remote_actors_added.each do |flipper_id|
            @operations << Operation.new(@feature, :enable_actor, Actor.new(flipper_id))
          end

          remote_actors_removed = local_actors - remote_actors
          remote_actors_removed.each do |flipper_id|
            @operations << Operation.new(@feature, :disable_actor, Actor.new(flipper_id))
          end
        end

        def diff_groups
          remote_groups_added = remote_groups - local_groups
          remote_groups_added.each do |group_name|
            @operations << Operation.new(@feature, :enable_group, group_name)
          end

          remote_groups_removed = local_groups - remote_groups
          remote_groups_removed.each do |group_name|
            @operations << Operation.new(@feature, :disable_group, group_name)
          end
        end

        def diff_percentage_of_actors
          return if local_percentage_of_actors == remote_percentage_of_actors

          @operations << Operation.new(@feature, :enable_percentage_of_actors, remote_percentage_of_actors)
        end

        def diff_percentage_of_time
          return if local_percentage_of_time == remote_percentage_of_time

          @operations << Operation.new(@feature, :enable_percentage_of_time, remote_percentage_of_time)
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
