require 'flipper/adapters/decorator'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter and stores the operations.
    #
    # Useful in tests to verify calls and such. Never use outside of testing.
    class OperationLogger < Decorator
      Operation = Struct.new(:type, :args)

      OperationTypes = [
        :features,
        :add,
        :remove,
        :clear,
        :get,
        :enable,
        :disable,
      ]

      # Internal: An array of the operations that have happened.
      attr_reader :operations

      # Public
      def initialize(adapter, operations = nil)
        super(adapter)
        @operations = operations || []
      end

      # Wraps original method with in memory log of operations performed.
      OperationTypes.each do |type|
        class_eval <<-EOE
          def #{type}(*args)
            @operations << Operation.new(:#{type}, args)
            super
          end
        EOE
      end

      # Public: Count the number of times a certain operation happened.
      def count(type)
        @operations.select { |operation| operation.type == type }.size
      end

      # Public: Resets the operation log to empty
      def reset
        @operations.clear
      end
    end
  end
end
