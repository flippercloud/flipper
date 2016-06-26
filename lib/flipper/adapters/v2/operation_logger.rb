module Flipper
  module Adapters
    module V2
      class OperationLogger < SimpleDelegator
        include ::Flipper::Adapter

        attr_reader :name

        def initialize(adapter, operations = nil)
          super(adapter)
          @adapter = adapter
          @name = :operation_logger
          @operations = operations || []
        end

        def version
          Adapter::V2
        end

        def get(key)
          @operations << Flipper::Adapters::OperationLogger::Operation.new(:get, [key])
          @adapter.get(key)
        end

        def set(key, value)
          @operations << Flipper::Adapters::OperationLogger::Operation.new(:set, [key, value])
          @adapter.set(key, value)
        end

        def del(key)
          @operations << Flipper::Adapters::OperationLogger::Operation.new(:del, [key])
          @adapter.del(key)
        end

        def count(type)
          @operations.select { |operation| operation.type == type }.size
        end

        def reset
          @operations.clear
        end
      end
    end
  end
end
