module Flipper
  module Expressions
    class All
      def self.call(*args)
        args.all?
      end

      def self.in_words(*args)
        count = args.length
        return args[0].in_words if count == 1

        "all #{count} conditions"
      end
    end
  end
end
