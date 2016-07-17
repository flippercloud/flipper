require 'flipper'
require 'pstore'

module Flipper
  module Adapters
    module V2
      class PStore
        include ::Flipper::Adapter

        # Public: The name of the adapter.
        attr_reader :name

        # Public: The path to where the file is stored.
        attr_reader :path

        def initialize(path = "flipper.pstore")
          @path = path
          @store = ::PStore.new(path)
          @name = :pstore
        end

        def version
          Adapter::V2
        end

        def get(key)
          @store.transaction do
            @store[key.to_s]
          end
        end

        def set(key, value)
          @store.transaction do
            @store[key.to_s] = value.to_s
          end
        end

        def del(key)
          @store.transaction do
            @store.delete(key.to_s)
          end
        end
      end
    end
  end
end
