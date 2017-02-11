module Flipper
  # Adding a module include so we have some hooks for stuff down the road
  module Adapter
    V1 = "1".freeze
    V2 = "2".freeze

    def version
      V1
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
