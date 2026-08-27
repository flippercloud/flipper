module Flipper
  module Expressions
    class Include
      def self.call(left, right)
        # ::String because String here resolves to Flipper::Expressions::String
        case left
        when ::Array
          left.include?(right)
        when ::String
          right.is_a?(::String) && left.include?(right)
        else
          false
        end
      end
    end
  end
end
