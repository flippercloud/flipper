module Flipper
  module Expressions
    class Now
      def self.call
        ::Time.now.utc
      end

      def self.in_words
        'now'
      end
    end
  end
end
