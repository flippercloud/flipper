require 'flipper'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter and raises for any writes.
    class ReadOnly < Wrapper
      WRITE_METHODS = %i[add remove clear enable disable]

      class WriteAttempted < Error
        def initialize(message = nil)
          super(message || 'write attempted while in read only mode')
        end
      end

      def read_only?
        true
      end

      private

      def wrap(method, *args, **kwargs)
        raise WriteAttempted if WRITE_METHODS.include?(method)

        yield
      end
    end
  end
end
