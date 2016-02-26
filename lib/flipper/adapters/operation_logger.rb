require 'flipper/adapters/decorator'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter and stores the operations.
    #
    # Useful in tests to verify calls and such. Never use outside of testing.
    class OperationLogger
      include Adapter

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

      # Internal: The name of the adapter.
      attr_reader :name

      # Public
      def initialize(adapter, operations = nil)
        @adapter = adapter
        @name = :operation_logger
        @operations = operations || []
      end

      # Wraps original method with in memory log of operations performed.
      OperationTypes.each do |type|
        class_eval <<-EOE
          def #{type}(*args)
            @operations << Operation.new(:#{type}, args)
            @adapter.send(:#{type}, *args)
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
