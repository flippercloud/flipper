module Flipper
  module Adapters
    class Sync
      # Internal: For keeping track of operations to make a local adapter equal
      # to a remote.
      class Operation
        attr_reader :feature, :name, :args

        def initialize(feature, name, *args)
          @feature = feature
          @name = name
          @args = args
        end

        def apply
          @feature.send @name, *@args
        end
      end
    end
  end
end
