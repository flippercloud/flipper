require "flipper/feature"
require "flipper/gate_values"
require "flipper/adapters/sync/operation"
require "flipper/adapters/sync/feature_diff"

module Flipper
  module Adapters
    class Sync
      class AdapterDiff
        attr_reader :operations

        def initialize(local, remote)
          @local = local
          @remote = remote
          @operations = []

          local_get_all = @local.get_all
          remote_get_all = @remote.get_all

          remote_get_all.each do |feature_key, remote_gates_hash|
            feature = Feature.new(feature_key, @local)
            # Check if feature_key is in hash before accessing to prevent unintended hash modification
            local_gates_hash = local_get_all.key?(feature_key) ? local_get_all[feature_key] : @local.default_config
            local_gate_values = GateValues.new(local_gates_hash)
            remote_gate_values = GateValues.new(remote_gates_hash)

            diff = FeatureDiff.new(feature, local_gate_values, remote_gate_values)
            @operations.concat diff.operations
          end

          # Add features that are missing in local and present in remote.
          features_to_add = remote_get_all.keys - local_get_all.keys
          features_to_add.each { |key|
            feature = Feature.new(key, @local)
            @operations << Operation.new(feature, :add)
          }

          # Remove features that are present in local and missing in remote.
          features_to_remove = local_get_all.keys - remote_get_all.keys
          features_to_remove.each { |key|
            feature = Feature.new(key, @local)
            @operations << Operation.new(feature, :remove)
          }
        end
      end
    end
  end
end
