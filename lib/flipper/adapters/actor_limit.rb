require "flipper/adapters/wrapper"

module Flipper
  module Adapters
    class ActorLimit < Wrapper
      LimitExceeded = Class.new(Flipper::Error)

      attr_reader :limit

      class << self
        # Returns whether sync mode is enabled for the current thread.
        # When sync mode is enabled, actor limits are not enforced,
        # allowing sync operations to bring local state in line with
        # remote state regardless of limits.
        def sync_mode
          Thread.current[:flipper_actor_limit_sync_mode]
        end

        def sync_mode=(value)
          Thread.current[:flipper_actor_limit_sync_mode] = value
        end

        # Executes a block with sync mode enabled. Actor limits will
        # not be enforced within the block.
        def with_sync_mode
          old_value = sync_mode
          self.sync_mode = true
          yield
        ensure
          self.sync_mode = old_value
        end
      end

      def initialize(adapter, limit = 100)
        super(adapter)
        @limit = limit
      end

      def enable(feature, gate, resource)
        if gate.is_a?(Flipper::Gates::Actor) && !self.class.sync_mode && over_limit?(feature, resource)
          raise LimitExceeded, "Actor limit of #{@limit} exceeded for feature #{feature.key}. See https://www.flippercloud.io/docs/features/actors#limitations"
        else
          super
        end
      end

      private

      def over_limit?(feature, resource)
        actors = feature.actors_value
        actors.size >= @limit && !actors.include?(resource.value)
      end
    end
  end
end
