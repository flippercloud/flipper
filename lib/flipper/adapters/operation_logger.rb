module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter and stores the operations.
    #
    # Useful in tests to verify calls and such. Never use outside of testing.
    class OperationLogger

      Operation = Struct.new(:type, :args)

      OperationTypes = [
        :get,
        :add,
        :enable,
        :disable,
        :features
      ]

      # Internal: An array of the operations that have happened.
      attr_reader :operations

      # Public: The name of the adapter.
      attr_reader :name

      # Public: The adapter whose operations will be logged.
      attr_reader :adapter

      # Public
      def initialize(adapter, operations = nil)
        @adapter = adapter
        @operations = operations || []
        @name = :operation_logger
      end

      OperationTypes.each do |type|
        class_eval <<-EOE
          def #{type}(*args)
            @operations << Operation.new(:#{type}, args)
            @adapter.#{type}(*args)
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

      # Public: Determines equality for an adapter instance when compared to
      # another object.
      def eql?(other)
        self.class.eql?(other.class) && adapter == other.adapter
      end
      alias_method :==, :eql?

      def inspect
        attributes = [
          "name=#{name.inspect}",
          "wrapped_adapter=#{adapter.inspect}",
          "operations=#{@operations.inspect}",
        ]
        "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
      end
    end
  end
end
