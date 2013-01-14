module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter and stores the operations.
    #
    # Useful in tests to verify calls and such.
    class OperationLogger
      attr_reader :operations

      Read      = Struct.new(:key)
      Write     = Struct.new(:key, :value)
      Delete    = Struct.new(:key)
      SetAdd    = Struct.new(:key, :value)
      SetDelete = Struct.new(:key, :value)
      SetMember = Struct.new(:key)

      # Public
      def initialize(adapter)
        @operations = []
        @adapter = adapter
      end

      # Public
      def read(key)
        @operations << Read.new(key.to_s)
        @adapter.read key
      end

      # Public
      def write(key, value)
        @operations << Write.new(key.to_s, value)
        @adapter.write key, value
      end

      # Public
      def delete(key)
        @operations << Delete.new(key.to_s, nil)
        @adapter.delete key
      end

      # Public
      def set_add(key, value)
        @operations << SetAdd.new(key.to_s, value)
        @adapter.set_add key, value
      end

      # Public
      def set_delete(key, value)
        @operations << SetDelete.new(key.to_s, value)
        @adapter.set_delete key, value
      end

      # Public
      def set_members(key)
        @operations << SetMembers.new(key.to_s)
        @adapter.set_members key
      end

      # Public: Clears operation log
      def reset
        @operations.clear
      end
    end
  end
end
