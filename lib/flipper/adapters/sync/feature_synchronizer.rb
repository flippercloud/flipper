require "flipper/actor"
require "flipper/gate_values"
require "flipper/adapters/sync/feature_diff"

module Flipper
  module Adapters
    class Sync
      # Internal: Given a feature, local gate values and remote gate values,
      # makes the local equal to the remote.
      class FeatureSynchronizer
        def initialize(feature, local_gate_values, remote_gate_values)
          @feature = feature
          @local_gate_values = local_gate_values
          @remote_gate_values = remote_gate_values
        end

        def call
          diff = FeatureDiff.new(@feature, @local_gate_values, @remote_gate_values)
          diff.operations.each(&:apply)
        end
      end
    end
  end
end
