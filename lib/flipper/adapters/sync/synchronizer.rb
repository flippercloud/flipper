require "flipper/adapters/sync/adapter_diff"

module Flipper
  module Adapters
    class Sync
      # Public: Given a local and remote adapter, it can update the local to
      # match the remote doing only the necessary enable/disable operations.
      class Synchronizer
        # Public: Initializes a new synchronizer.
        #
        # local - The Flipper adapter to get in sync with the remote.
        # remote - The Flipper adapter that is source of truth that the local
        #          adapter should be brought in line with.
        # options - The Hash of options.
        #           :instrumenter - The instrumenter used to instrument.
        #           :raise - Should errors be raised (default: true).
        def initialize(local, remote, options = {})
          @local = local
          @remote = remote
          @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
          @raise = options.fetch(:raise, true)
        end

        # Public: Forces a sync.
        def call
          @instrumenter.instrument("synchronizer_call.flipper") { sync }
        end

        private

        def sync
          diff = AdapterDiff.new(@local, @remote)
          diff.operations.each(&:apply)

          nil
        rescue => exception
          @instrumenter.instrument("synchronizer_exception.flipper", exception: exception)
          raise if @raise
        end
      end
    end
  end
end
