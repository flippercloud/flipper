module Flipper
  class MemoryAdapter
    def initialize(source = nil)
      @source = source || {}
    end

    def read(key)
      @source[key]
    end

    def write(key, value)
      @source[key] = value
    end

    def delete(key)
      @source.delete(key)
    end

    def set_add(key, value)
      set_members(key).add(value)
    end

    def set_delete(key, value)
      set_members(key).delete(value)
    end

    def set_members(key)
      @source[key] ||= Set.new
    end

    def clear
      @source.clear
    end
  end
end
