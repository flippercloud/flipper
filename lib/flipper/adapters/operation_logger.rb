module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter and stores the operations.
    #
    # Useful in tests to verify calls and such. Never use outside of testing.
    class OperationLogger < SimpleDelegator

      # Internal: An array of the operations that have happened.
      attr_reader :operations

      Operation = Struct.new(:type, :args)

      OperationTypes = [
        :get,
        :add,
        :enable,
        :disable,
        :features
      ]

      # Public
      def initialize(*args)
        super
        @operations = []
      end

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
