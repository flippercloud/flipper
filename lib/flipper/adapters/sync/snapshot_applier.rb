require "flipper/feature"
require "flipper/gate_values"
require "flipper/adapters/sync/feature_synchronizer"

module Flipper
  module Adapters
    class Sync
      # Internal: Reconcile data without fetching or making revision decisions.
      # Atomic adapters call this only inside their storage boundary.
      class SnapshotApplier
        def initialize(local, features, instrumenter: Instrumenters::Noop)
          @local = local
          @features = features
          @instrumenter = instrumenter
        end

        def call
          current = @local.get_all
          return :unchanged if current == @features

          @features.each do |key, gates|
            feature = Feature.new(key, @local, instrumenter: @instrumenter)
            local_gates = current.key?(key) ? current[key] : @local.default_config
            FeatureSynchronizer.new(feature, GateValues.new(local_gates), GateValues.new(gates)).call
          end

          (@features.keys - current.keys).each do |key|
            Feature.new(key, @local, instrumenter: @instrumenter).add
          end
          (current.keys - @features.keys).each do |key|
            Feature.new(key, @local, instrumenter: @instrumenter).remove
          end
          :applied
        end
      end
    end
  end
end
