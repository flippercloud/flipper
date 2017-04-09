module Flipper
  # Adding a module include so we have some hooks for stuff down the road
  module Adapter
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
    def import(adapter)
      actor_class = Struct.new(:flipper_id)

      adapter.features.each do |key|
        feature = Flipper::Feature.new(key, adapter)
        destination_feature = Flipper::Feature.new(key, self)
        clear(destination_feature)

        case feature.state
        when :on
          destination_feature.enable
        when :conditional
          feature.groups_value.each do |value|
            destination_feature.enable_group(value)
          end

          feature.actors_value.each do |value|
            destination_feature.enable_actor(actor_class.new(value))
          end

          destination_feature.enable_percentage_of_actors(feature.percentage_of_actors_value)
          destination_feature.enable_percentage_of_time(feature.percentage_of_time_value)
        when :off
          add(feature)
        end
      end

      nil
    end

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
end
