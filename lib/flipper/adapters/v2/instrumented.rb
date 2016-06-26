require 'delegate'
require 'flipper/adapters/v2/set_interface'

module Flipper
  module Adapters
    module V2
      # Internal: Adapter that wraps another adapter and instruments all adapter
      # operations. Used by flipper dsl to provide instrumentatin for flipper.
      class Instrumented < SimpleDelegator
        include ::Flipper::Adapter

        # Private: The name of instrumentation events.
        InstrumentationName = "adapter_operation.#{InstrumentationNamespace}"

        # Private: What is used to instrument all the things.
        attr_reader :instrumenter

        # Public: The name of the adapter.
        attr_reader :name

        # Internal: Initializes a new adapter instance.
        #
        # adapter - Vanilla adapter instance to wrap.
        #
        # options - The Hash of options.
        #           :instrumenter - What to use to instrument all the things.
        #
        def initialize(adapter, options = {})
          super(adapter)
          @adapter = adapter
          @name = :instrumented
          @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
        end

        def get(key)
          payload = {
            :operation => :get,
            :adapter_name => @adapter.name,
          }

          @instrumenter.instrument(InstrumentationName, payload) { |payload|
            payload[:result] = @adapter.get(key)
          }
        end

        def set(key, value)
          payload = {
            :operation => :set,
            :adapter_name => @adapter.name,
          }

          @instrumenter.instrument(InstrumentationName, payload) { |payload|
            payload[:result] = @adapter.set(key, value)
          }
        end

        def del(key)
          payload = {
            :operation => :del,
            :adapter_name => @adapter.name,
          }

          @instrumenter.instrument(InstrumentationName, payload) { |payload|
            payload[:result] = @adapter.del(key)
          }
        end

        # Public: Override with data store specific implementation that is
        # more efficient/transactional.
        def mget(keys)
          payload = {
            :operation => :mget,
            :adapter_name => @adapter.name,
          }

          @instrumenter.instrument(InstrumentationName, payload) { |payload|
            payload[:result] = @adapter.mget(keys)
          }
        end

        # Public: Override with data store specific implementation that is
        # more efficient/transactional.
        def mset(kvs)
          payload = {
            :operation => :mset,
            :adapter_name => @adapter.name,
          }

          @instrumenter.instrument(InstrumentationName, payload) { |payload|
            payload[:result] = @adapter.mset(kvs)
          }
        end

        # Public: Override with data store specific implementation that is
        # more efficient/transactional.
        def mdel(keys)
          payload = {
            :operation => :mdel,
            :adapter_name => @adapter.name,
          }

          @instrumenter.instrument(InstrumentationName, payload) { |payload|
            payload[:result] = @adapter.mdel(keys)
          }
        end

        # Public: Override with data store specific implementation that is
        # more efficient/transactional.
        def smembers(key)
          payload = {
            :operation => :smembers,
            :adapter_name => @adapter.name,
          }

          @instrumenter.instrument(InstrumentationName, payload) { |payload|
            payload[:result] = @adapter.smembers(key)
          }
        end

        # Public: Override with data store specific implementation that is
        # more efficient/transactional.
        def sadd(key, value)
          payload = {
            :operation => :sadd,
            :adapter_name => @adapter.name,
          }

          @instrumenter.instrument(InstrumentationName, payload) { |payload|
            payload[:result] = @adapter.sadd(key, value)
          }
        end

        # Public: Override with data store specific implementation that is
        # more efficient/transactional.
        def srem(key, value)
          payload = {
            :operation => :srem,
            :adapter_name => @adapter.name,
          }

          @instrumenter.instrument(InstrumentationName, payload) { |payload|
            payload[:result] = @adapter.srem(key, value)
          }
        end

        # Private
        def sdump(object)
          @adapter.sdump(object)
        end

        # Private
        def sload(object)
          @adapter.sload(object)
        end
      end
    end
  end
end
