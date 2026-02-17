require "set"

module Flipper
  module Expressions
    class FeatureEnabled
      EVALUATING_KEY = :flipper_evaluating_features

      def self.call(feature_name, context:)
        evaluating = Thread.current[EVALUATING_KEY] ||= Set.new
        feature_name = feature_name.to_s
        current_feature = context[:feature_name].to_s

        # Track the current feature so A -> B -> A is caught
        added_current = evaluating.add?(current_feature)

        begin
          # Circular dependency: return false to break the cycle
          return false if evaluating.include?(feature_name)

          evaluating.add(feature_name)
          actor = context[:actor]
          if actor
            Flipper.enabled?(feature_name, actor)
          else
            Flipper.enabled?(feature_name)
          end
        ensure
          evaluating.delete(feature_name)
          evaluating.delete(current_feature) if added_current
        end
      end
    end
  end
end
