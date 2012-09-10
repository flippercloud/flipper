module Flipper
  class Key
    Separator = '/'

    attr_reader :prefix, :suffix

    def initialize(prefix, suffix)
      @prefix, @suffix = prefix, suffix
    end

    def separator
      Separator.dup
    end

    def to_s
      "#{prefix}#{separator}#{suffix}"
    end
  end
end
