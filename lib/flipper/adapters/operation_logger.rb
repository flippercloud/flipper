require 'delegate'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter and stores the operations.
    #
    # Useful in tests to verify calls and such. Never use outside of testing.
    class OperationLogger < Wrapper

      class Operation
        attr_reader :type, :args, :kwargs

        def initialize(type, args, kwargs = {})
          @type = type
          @args = args
          @kwargs = kwargs
        end
      end

      # Internal: An array of the operations that have happened.
      attr_reader :operations

      # Public
      def initialize(adapter, operations = nil)
        super(adapter)
        @operations = operations || []
      end

      # Public: Count the number of times a certain operation happened.
      def count(type = nil)
        if type
          type(type).size
        else
          @operations.size
        end
      end

      # Public: Get all operations of a certain type.
      def type(type)
        @operations.select { |operation| operation.type == type }
      end

      # Public: Get the last operation of a certain type.
      def last(type)
        @operations.reverse.find { |operation| operation.type == type }
      end

      # Public: Resets the operation log to empty
      def reset
        @operations.clear
      end

      def inspect
        inspect_id = ::Kernel::format "%x", (object_id * 2)
        %(#<#{self.class}:0x#{inspect_id} @name=#{name.inspect}, @operations=#{@operations.inspect}, @adapter=#{@adapter.inspect}>)
      end

      private

      def wrap(method, *args, **kwargs, &block)
        @operations << Operation.new(method, args, kwargs)
        block.call
      end
    end
  end
end
