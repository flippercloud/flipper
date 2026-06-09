module Flipper
  module Expressions
    class Max
      def self.call(*args)
        args.max
      rescue ArgumentError
        nil
      end
    end
  end
end
