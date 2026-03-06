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

      class << self
        # Returns whether sync mode is enabled for the current thread.
        # When sync mode is enabled, strict checks are not enforced,
        # allowing sync operations to add features and bring local state
        # in line with remote state.
        def sync_mode
          Thread.current[:flipper_strict_sync_mode]
        end

        def sync_mode=(value)
          Thread.current[:flipper_strict_sync_mode] = value
        end

        # Executes a block with sync mode enabled. Strict checks will
        # not be enforced within the block.
        def with_sync_mode
          old_value = sync_mode
          self.sync_mode = true
          yield
        ensure
          self.sync_mode = old_value
        end
      end

      def initialize(adapter, handler = nil, &block)
        super(adapter)
        @handler = block || handler
      end

      def add(feature)
        assert_feature_exists(feature) unless self.class.sync_mode
        super
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
        return if self.class.sync_mode
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
