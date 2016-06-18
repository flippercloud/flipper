module Flipper
  module Adapter
    # adding a module include so we have some hooks for stuff down the road

    V1 = "1".freeze

    def version
      V1
    end
  end
end
