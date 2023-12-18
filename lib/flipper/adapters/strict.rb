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

      def_delegators :@adapter, :features, :get_all, :add, :remove, :clear, :enable, :disable

      def initialize(adapter, handler = nil, &block)
        @name = :strict
        @adapter = adapter
        @handler = block || handler
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
        return if @adapter.features.include?(feature.key)

        case handler
        when Proc then handler.call(feature)
        when true, :raise then raise NotFound.new(feature.key)
        when :warn then warn NotFound.new(feature.key).message
        else
          # noop or unknown handler
        end
      end

    end
  end
end
