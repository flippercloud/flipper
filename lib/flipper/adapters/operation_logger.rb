module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter and stores the operations.
    #
    # Useful in tests to verify calls and such.
    class OperationLogger
      extend Forwardable

      # Forward soon to be private adapter methods to source adapter
      def_delegators :@adapter, :read, :write, :delete,
        :set_members, :set_add, :set_delete

      # Internal: An array of the operations that have happened.
      attr_reader :operations

      Get      = Struct.new(:feature)
      Enable   = Struct.new(:feature, :gate, :thing)
      Disable  = Struct.new(:feature, :gate, :thing)
      Add      = Struct.new(:feature)
      Features = Struct.new(:features)

      # Public
      def initialize(adapter)
        @operations = []
        @adapter = adapter
      end

      # Public
      def get(feature)
        @operations << Get.new(feature)
        @adapter.get feature
      end

      # Public
      def enable(feature, gate, thing)
        @operations << Enable.new(feature, gate, thing)
        @adapter.enable feature, gate, thing
      end

      # Public
      def disable(feature, gate, thing)
        @operations << Disable.new(feature, gate, thing)
        @adapter.disable feature, gate, thing
      end

      def add(feature)
        @operations << Add.new(feature)
        @adapter.add(feature)
      end

      def features
        features = @adapter.features
        @operations << FeatureNames.new(features)
        features
      end

      # Public: Resets the operation log to empty
      def reset
        @operations.clear
      end
    end
  end
end
