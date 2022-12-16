module Flipper
  module Instrumentation
    class Bugsnag
      def call(name, start, finish, id, payload)
        operation, feature_name, result = payload.values_at(:operation, :feature_name, :result)
        return unless operation == :enabled?

        if result
          ::Bugsnag.add_feature_flag(feature_name)
        else
          ::Bugsnag.clear_feature_flag(feature_name)
        end
      end
    end

    # Register the subscriber if using ActiveSupport::Notifications
    if defined?(ActiveSupport::Notifications)
      ActiveSupport::Notifications.subscribe('feature_operation.flipper', Bugsnag.new)
    end
  end
end
