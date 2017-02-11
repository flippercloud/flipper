require 'flipper'
require 'flipper/adapters/read_only'

module Flipper
  module Adapters
    module V2
      class ReadOnly
        include ::Flipper::Adapter

        # Public: The name of the adapter.
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

        def set(_key, _value)
          raise Flipper::Adapters::ReadOnly::WriteAttempted
        end

        def del(_key)
          raise Flipper::Adapters::ReadOnly::WriteAttempted
        end
      end
    end
  end
end
