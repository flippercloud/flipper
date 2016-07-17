require 'flipper'
require 'pstore'

module Flipper
  module Adapters
    module V2
      class PStore
        include ::Flipper::Adapter

        attr_reader :name, :path

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
