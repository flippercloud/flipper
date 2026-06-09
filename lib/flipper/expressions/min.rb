module Flipper
  module Expressions
    class Min
      def self.call(*args)
        args.min
      rescue ArgumentError
        nil
      end
    end
  end
end
