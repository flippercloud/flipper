module Flipper
  module Adapters
    # An adapter that ensures a feature exists before checking it.
    class Strict
      extend Forwardable
      include ::Flipper::Adapter
      attr_reader :name, :adapter, :handler

      class NotFound < ::Flipper::Error
        def initialize(name)
          super "Could not find feature #{name.inspect}. Call `Flipper.add(#{name.inspect})` to create it."
        end
      end

      HANDLERS = {
        raise: ->(feature) { raise NotFound.new(feature.key) },
        warn: ->(feature) { warn NotFound.new(feature.key).message },
        noop: ->(_) { },
      }

      def_delegators :@adapter, :features, :get_all, :add, :remove, :clear, :enable, :disable

      def initialize(adapter, handler = nil, &block)
        @name = :strict
        @adapter = adapter
        @handler = block || HANDLERS.fetch(handler)
      end

      def get(feature)
        assert_feature_exists(feature)
        @adapter.get(feature)
      end

      def get_multi(features)
        features.each { |feature| assert_feature_exists(feature) }
        @adapter.get_multi(features)
      end

      private

      def assert_feature_exists(feature)
        @handler.call(feature) unless @adapter.features.include?(feature.key)
      end

    end
  end
end
