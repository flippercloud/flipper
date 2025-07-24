module Flipper
  module Expressions
    class Any
      def self.call(*args)
        args.any?
      end

      def self.in_words(*args)
        count = args.length
        return args[0].in_words if count == 1

        "any #{count} conditions"
      end
    end
  end
end
