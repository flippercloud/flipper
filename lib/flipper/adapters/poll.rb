require 'flipper/adapters/dual_write'
require 'flipper/poller'

module Flipper
  module Adapters
    # An adapter that keeps a local and remote adapter in sync via a background poller.
    #
    # Synchronization is performed when the adapter is accessed if the background
    # poller has synced.
    class Poll < DualWrite
      # Public: The Poller used to sync in a background thread.
      attr_reader :poller

      # Instantiate a new Poll adapter.
      #
      #   local = Flipper::Adapters::ActiveRecord.new
      #   remote = Flipper::Adapters::Http.new(url: 'http://example.com/flipper')
      #   adapter = Flipper::Adapters::Poll.new(local, remote, key: 'unique_poller_name', interval: 5)
      #
      # local - Local adapter that will be used for reads and gets synchronized on an interval.
      # remote - Remote adapter that will be polled on an interval.
      # key: The key used to identify the poller.
      # **options: Options to pass to the poller. See Flipper::Poller for options.
      def initialize(local, remote, key:, **options)
        super(local, remote)
        @name = :poll
        @poller = Flipper::Poller.get(key, remote, options).tap(&:start)
        @last_synced_at = 0
        @sync_automatically = true
      end

      # Public: Synchronizes the local adapter with the current state of the remote adapter.
      # If given a block, the adapter will be synced once and then not synced again for the
      # duration of the block.
      #
      #   poll = Flipper::Adapters::Poll.new(local, remote)
      #   poll.sync do
      #     # Long running operation that doesn't need to be synced
      #   end
      def sync
        if @sync_automatically
          poller_last_synced_at = @poller.last_synced_at.value
          if poller_last_synced_at > @last_synced_at
            @local.import(@poller.adapter)
            @last_synced_at = poller_last_synced_at
          end
        end
        if block_given?
          begin
            sync_automatically_was, @sync_automatically = @sync_automatically, false
            yield
          ensure
            @sync_automatically = sync_automatically_was
          end
        end
      end

      %i[features get get_multi get_all add remove clear enable disable].each do |method|
        define_method(method) do |*args|
          sync { super(*args) }
        end
      end
    end
  end
end
