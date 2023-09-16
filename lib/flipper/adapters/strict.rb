module Flipper
  module Adapters
    # An adapter that ensures a feature exists before checking it.
    class Strict
      extend Forwardable
      include ::Flipper::Adapter
      attr_reader :name, :adapter

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

      DEFAULT_NOT_FOUND =

      def_delegators :@adapter, :features, :get, :get_multi, :get_all, :add, :remove, :clear, :enable, :disable

      def initialize(adapter, name: :strict, handler: :raise)
        @name = name
        @adapter = adapter
        @handler = handler.is_a?(Symbol) ? HANDLERS.fetch(handler) : handler
      end

      def get(feature)
        assert_feature_exists(feature)
        @adapter.get(feature)
      end

      private

      def assert_feature_exists(feature)
        @handler.call(feature) unless @adapter.features.include?(feature.key)
      end

    end
  end
end
