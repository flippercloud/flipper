module Flipper
  module Expressions
    class All
      def self.call(*args)
        args.all?
      end
    end
  end
end
