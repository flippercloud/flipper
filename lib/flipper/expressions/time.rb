module Flipper
  module Expressions
    class Time
      def self.call(value)
        ::Time.parse(value)
      end

      def self.in_words(arg)
        self.call(arg.value)
      end
    end
  end
end
