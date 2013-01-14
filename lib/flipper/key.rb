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

    # Public: Pretty string version for debugging.
    def inspect
      attributes = [
        "prefix=#{prefix.inspect}",
        "suffix=#{suffix.inspect}",
      ]
      "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
    end
  end
end
