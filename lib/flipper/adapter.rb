module Flipper
  # Adding a module include so we have some hooks for stuff down the road
  module Adapter
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Public: Default config for a feature's gate values.
      def default_config
        {
          boolean: nil,
          groups: Set.new,
          actors: Set.new,
          percentage_of_actors: nil,
          percentage_of_time: nil,
        }
      end
    end

    # Public: Get multiple features in one call. Defaults to one get per
    # feature. Feel free to override per adapter to make this more efficient and
    # reduce network calls.
    def get_multi(features)
      result = {}
      features.each do |feature|
        result[feature.key] = get(feature)
      end
      result
    end

    # Public: Wipe features and gate values and then import features and gate
    # values from provided adapter.
    #
    # Returns nothing.
    def import(source_adapter)
      wipe
      copy_features_and_gates(source_adapter)
      nil
    end

    # Public: Default config for a feature's gate values.
    def default_config
      self.class.default_config
    end

    private

    # Private: Copy source adapter features and gate values into self.
    def copy_features_and_gates(source_adapter)
      source_adapter.features.each do |key|
        source_feature = Flipper::Feature.new(key, source_adapter)
        destination_feature = Flipper::Feature.new(key, self)

        case source_feature.state
        when :on
          destination_feature.enable
        when :conditional
          source_feature.groups_value.each do |value|
            destination_feature.enable_group(value)
          end

          source_feature.actors_value.each do |value|
            destination_feature.enable_actor(Flipper::Actor.new(value))
          end

          destination_feature.enable_percentage_of_actors(source_feature.percentage_of_actors_value)
          destination_feature.enable_percentage_of_time(source_feature.percentage_of_time_value)
        when :off
          destination_feature.add
        end
      end
    end

    # Private: Completely wipe adapter features and gate values.
    def wipe
      features.each do |key|
        feature = Flipper::Feature.new(key, self)
        remove(feature)
      end
    end
  end
end
