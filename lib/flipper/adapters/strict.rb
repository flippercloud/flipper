module Flipper
  module Adapters
    # An adapter that ensures a feature exists before checking it.
    class Strict < Wrapper
      attr_reader :handler

      class NotFound < ::Flipper::Error
        def initialize(name)
          super "Could not find feature #{name.inspect}. Call `Flipper.add(#{name.inspect})` to create it."
        end
      end

      def initialize(adapter, handler = nil, &block)
        super(adapter)
        @handler = block || handler
      end

      def get(feature)
        assert_feature_exists(feature)
        super
      end

      def get_multi(features)
        features.each { |feature| assert_feature_exists(feature) }
        super
      end

      private

      def assert_feature_exists(feature)
        return if @adapter.features.include?(feature.key)

        case handler
        when Proc then handler.call(feature)
        when :warn then warn NotFound.new(feature.key).message
        when :noop, false, nil
         # noop
        else # truthy or :raise
         raise NotFound.new(feature.key)
        end
      end

    end
  end
end
