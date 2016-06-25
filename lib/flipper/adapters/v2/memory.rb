require 'flipper/adapters/v2/set_interface'

module Flipper
  module Adapters
    module V2
      # Public: Adapter for storing everything in memory (ie: Hash).
      # Useful for tests/specs.
      class Memory
        include ::Flipper::Adapter
        include ::Flipper::Adapters::V2::SetInterface

        attr_reader :name

        def initialize(source = nil)
          @source = source || {}
          @name = :memory
        end

        def get(key)
          value = @source[key]
          if value =~ SET_VALUE_REGEXP
            value = sload(value)
          end
          value
        end

        def set(key, value)
          @source[key] = value.to_s
          true
        end

        def del(key)
          @source.delete(key)
          true
        end

        # Public: Override with data store specific implementation that is
        # more efficient/transactional.
        def mget(keys)
          hash = {}
          keys.each do |key|
            hash[key] = get(key)
          end
          hash
        end

        # Public: Override with data store specific implementation that is
        # more efficient/transactional.
        def mset(kvs)
          kvs.each do |key, value|
            set(key, value)
          end

          true
        end

        # Public: Override with data store specific implementation that is
        # more efficient/transactional.
        def mdel(keys)
          keys.each { |key| del(key) }

          true
        end

        # Public
        def inspect
          attributes = [
            "name=:memory",
            "source=#{@source.inspect}",
          ]
          "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
        end
      end
    end
  end
end
