module Flipper
  module Instrumenters
    class Noop
      def self.instrument(name, payload = {})
        yield
      end
    end
  end
end
