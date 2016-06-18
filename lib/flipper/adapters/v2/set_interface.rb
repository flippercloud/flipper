require 'set'

module Flipper
  module Adapters
    module V2
      module SetInterface
        SET_SEPARATOR = ",".freeze
        SET_PREFIX = "flipper_set:".freeze
        SET_VALUE_REGEXP = /^#{SET_PREFIX}/
        SET_SERIALIZER = lambda { |object| object.to_a.join(SET_SEPARATOR) }
        SET_DESERIALIZER = lambda { |raw| raw.to_s.split(SET_SEPARATOR).to_set }

        # Public: Override with data store specific implementation that is
        # more efficient/transactional.
        def smembers(key)
          get(key) || Set.new
        end

        # Public: Override with data store specific implementation that is
        # more efficient/transactional.
        def sadd(key, value)
          value = value.to_s
          members = smembers(key)

          if members.include?(value)
            false
          else
            members.add(value)
            set(key, sdump(members))
            true
          end
        end

        # Public: Override with data store specific implementation that is
        # more efficient/transactional.
        def srem(key, value)
          value = value.to_s
          members = smembers(key)

          if members.include?(value)
            members.delete(value)
            set(key, sdump(members))
            true
          else
            false
          end
        end

        # Private
        def sdump(object)
          SET_PREFIX + SET_SERIALIZER.call(object)
        end

        # Private
        def sload(object)
          SET_DESERIALIZER.call(object.to_s.gsub(SET_VALUE_REGEXP, ""))
        end
      end
    end
  end
end
