module Flipper
  module Expressions
    class Include
      def self.call(left, right)
        left.respond_to?(:include?) && left.include?(right)
      end
    end
  end
end
