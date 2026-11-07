require 'flipper'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter and raises for any writes.
    class ReadOnly < Wrapper
      WRITE_METHODS = %i[import add remove clear enable disable apply_snapshot]

      class WriteAttempted < Error
        def initialize(message = nil)
          super(message || 'write attempted while in read only mode')
        end
      end

      def read_only?
        true
      end

      def supports?(feature)
        return false if feature.to_sym == :atomic_snapshot_install
        super
      end

      private

      def wrap(method, *args, **kwargs)
        raise WriteAttempted if WRITE_METHODS.include?(method)

        yield
      end
    end
  end
end
