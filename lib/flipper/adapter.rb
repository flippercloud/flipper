module Flipper
  # Adapter wrapper that wraps vanilla adapter instances with local caching.
  #
  # So what is this local cache crap?
  #
  # The main goal of the local cache is to prevent multiple queries to an
  # adapter for the same key for a given amount of time (per request, per
  # background job, etc.).
  #
  # To facilitate with this, there is an included local cache middleware
  # that enables local caching for the length of a web request. The local
  # cache is enabled and cleared before each request and cleared and reset
  # to original value after each request.
  #
  # Examples
  #
  # To see an example adapter that this would wrap, checkout the [memory
  # adapter included with flipper](https://github.com/jnunemaker/flipper/blob/master/lib/flipper/adapters/memory.rb).
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

    def using_local_cache?
      @use_local_cache == true
    end

    def read(key)
      if using_local_cache?
        cache(key) { @adapter.read(key) }
      else
        @adapter.read(key)
      end
    end

    def write(key, value)
      @adapter.write(key, value).tap { expire_local_cache(key) }
    end

    def delete(key)
      @adapter.delete(key).tap { expire_local_cache(key) }
    end

    def set_members(key)
      if using_local_cache?
        cache(key) { @adapter.set_members(key) }
      else
        @adapter.set_members(key)
      end
    end

    def set_add(key, value)
      @adapter.set_add(key, value).tap { expire_local_cache(key) }
    end

    def set_delete(key, value)
      @adapter.set_delete(key, value).tap { expire_local_cache(key) }
    end

    def eql?(other)
      self.class.eql?(other.class) && adapter == other.adapter
    end
    alias :== :eql?

    private

    def cache(key)
      local_cache.fetch(key) { local_cache[key] = yield }
    end

    def expire_local_cache(key)
      local_cache.delete(key) if using_local_cache?
    end
  end
end
