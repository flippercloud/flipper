module Flipper
  module Adapters
    module V2
      class ReadOnly
        include ::Flipper::Adapter

        attr_reader :name

        def initialize(adapter)
          @adapter = adapter
          @name = :read_only
        end

        def version
          Adapter::V2
        end

        def get(key)
          @adapter.get(key)
        end

        def set(key, value)
          raise Flipper::Adapters::ReadOnly::WriteAttempted
        end

        def del(key)
          raise Flipper::Adapters::ReadOnly::WriteAttempted
        end
      end
    end
  end
end
