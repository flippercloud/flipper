module Flipper
  module Adapters
    class Rest
      def initialize(mount)
        @mount = mount
      end

      def url(path)
        "#{@mount}/#{path}"
      end
    end
  end
end
