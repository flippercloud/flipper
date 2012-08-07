module Flipper
  class Adapter
    def self.wrap(object)
      if object.is_a?(Flipper::Adapter)
        object
      else
        new(object)
      end
    end

    attr_reader :adapter, :use_local_cache

    def initialize(adapter)
      @adapter = adapter
    end

    def use_local_cache=(value)
      local_cache.clear
      @use_local_cache = value
    end

    def local_cache
      @local_cache ||= {}
    end

    def use_local_cache?
      @use_local_cache == true
    end

    def read(key)
      if use_local_cache?
        local_cache.fetch(key) {
          local_cache[key] = @adapter.read(key)
        }
      else
        @adapter.read(key)
      end
    end

    def write(key, value)
      result = @adapter.write(key, value)
      local_cache.delete(key) if use_local_cache?
      result
    end

    def delete(key)
      result = @adapter.delete(key)
      local_cache.delete(key) if use_local_cache?
      result
    end

    def set_members(key)
      if use_local_cache?
        local_cache.fetch(key) {
          local_cache[key] = @adapter.set_members(key)
        }
      else
        @adapter.set_members(key)
      end
    end

    def set_add(key, value)
      result = @adapter.set_add(key, value)
      local_cache.delete(key) if use_local_cache?
      result
    end

    def set_delete(key, value)
      result = @adapter.set_delete(key, value)
      local_cache.delete(key) if use_local_cache?
      result
    end

    def eql?(other)
      self.class.eql?(other.class) && adapter == other.adapter
    end
    alias :== :eql?
  end
end
