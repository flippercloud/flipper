require "flipper/feature"
require "flipper/gate_values"
require "flipper/instrumenters/noop"
require "flipper/adapters/sync/feature_synchronizer"

module Flipper
  module Adapters
    class Sync
      # Internal: Given a local and remote adapter, it can update the local to
      # match the remote doing only the necessary enable/disable operations.
      class Synchronizer
        def initialize(local, remote, options = {})
          @local = local
          @remote = remote
          @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
        end

        def call
          @instrumenter.instrument("synchronizer_call.flipper") { sync }
        end

        private

        def sync
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
          features_to_add.each { |key| Feature.new(key, @local).add }
        rescue => exception
          @instrumenter.instrument("synchronizer_exception.flipper", exception: exception)
        end
      end
    end
  end
end
