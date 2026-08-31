require "set"

module Flipper
  module Expressions
    class FeatureEnabled
      EVALUATING_KEY = :flipper_evaluating_features

      def self.call(feature_name, context:)
        evaluating = Thread.current[EVALUATING_KEY] ||= Set.new
        feature_name = feature_name.to_s
        current_feature = context[:feature_name].to_s
        instance_key = context[:flipper_instance_key]
        feature_identity = instance_key ? [instance_key, feature_name] : feature_name
        current_identity = instance_key ? [instance_key, current_feature] : current_feature

        # Track the current feature so A -> B -> A is caught
        added_current = evaluating.add?(current_identity)

        begin
          # Circular dependency: return false to break the cycle
          return false if evaluating.include?(feature_identity)

          evaluating.add(feature_identity)
          actor = context[:actor]
          feature_resolver = context.fetch(:feature_resolver, Flipper)
          if actor
            feature_resolver.enabled?(feature_name, actor)
          else
            feature_resolver.enabled?(feature_name)
          end
        ensure
          evaluating.delete(feature_identity)
          evaluating.delete(current_identity) if added_current
        end
      end
    end
  end
end
