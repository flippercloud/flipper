module Flipper
  class Registry
    class Error < StandardError; end
    class DuplicateKey < Error; end
    class MissingKey < Error; end

    def initialize(source = {})
      @mutex = Mutex.new
      @source = source
    end

    def add(key, value)
      @mutex.synchronize do
        if @source[key]
          raise DuplicateKey, "#{key} is already registered"
        else
          @source[key] = value
        end
      end
    end

    def get(key)
      @mutex.synchronize do
        @source[key]
      end
    end

    def each(&block)
      @mutex.synchronize { @source.dup }.each(&block)
    end

    def clear
      @mutex.synchronize { @source.clear }
    end
  end
end
