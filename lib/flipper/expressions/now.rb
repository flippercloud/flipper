module Flipper
  module Expressions
    class Now
      def self.call
        ::Time.now.utc
      end
    end
  end
end
