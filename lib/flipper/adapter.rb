module Flipper
  module Adapter
    # adding a module include so we have some hooks for stuff down the road
    def get_multi(features)
      features.map { |feature| get(feature) }
    end
  end
end
