module Flipper
  module Expressions
    class Any
      def self.call(*args)
        args.any?
      end
    end
  end
end
