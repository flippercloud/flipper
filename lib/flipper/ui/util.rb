module Flipper
  module UI
    module Util
      # Private: 0x3000: fullwidth whitespace
      NON_WHITESPACE_REGEXP = %r![^\s#{[0x3000].pack("U")}]!

      def self.blank?(str)
        str.to_s !~ NON_WHITESPACE_REGEXP
      end

      def self.titleize(str)
        str.to_s.split("_").map { |word| word.capitalize }.join(" ")
      end
    end
  end
end
