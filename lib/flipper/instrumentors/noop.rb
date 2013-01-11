module Flipper
  module Instrumentors
    class Noop
      def self.instrument(name, payload = {})
        yield
      end
    end
  end
end
