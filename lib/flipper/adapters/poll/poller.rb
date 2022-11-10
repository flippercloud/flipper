require 'logger'
require 'concurrent/atomic/read_write_lock'
require 'concurrent/utility/monotonic_time'
require 'concurrent/map'

module Flipper
  module Adapters
    class Poll
      class Poller
        PREFIX = "[flipper http async poll adapter]".freeze

        attr_reader :thread, :pid, :mutex, :logger, :interval, :last_synced_at

        def self.instances
          @instances ||= Concurrent::Map.new
        end
        private_class_method :instances

        def self.get(key, options = {})
          instances.compute_if_absent(key) { new(options) }
        end

        def initialize(options = {})
          @thread = nil
          @pid = Process.pid
          @mutex = Mutex.new
          @adapter = Memory.new
          @remote_adapter = options.fetch(:remote_adapter)
          @logger = options.fetch(:logger) { Logger.new(STDOUT) }
          @interval = options.fetch(:interval, 10).to_f
          @lock = Concurrent::ReadWriteLock.new
          @last_synced_at = Concurrent::AtomicFixnum.new(0)

          if @interval < 1
            warn "#{PREFIX} interval must be greater than or equal to 1 but was #{@interval}. Setting @interval to 1."
            @interval = 1
          end

          @start_automatically = options.fetch(:start_automatically, true)

          if options.fetch(:shutdown_automatically, true)
            at_exit { stop }
          end
        end

        def adapter
          @lock.with_read_lock { Memory.new(@adapter.get_all.dup) }
        end

        def start
          reset if forked?
          ensure_worker_running
        end

        def stop
          logger.debug { "#{PREFIX} Stopping worker" }
          @thread&.kill
        end

        def run
          loop do
            start = Concurrent.monotonic_time
            begin
              logger.debug { "#{PREFIX} Making a checkity checkity" }

              adapter = Memory.new
              adapter.import(@remote_adapter)

              @lock.with_write_lock {
                @adapter.import(adapter)
                @last_synced_at.update { |time| Concurrent.monotonic_time }
              }
            rescue => exception
              logger.debug { "#{PREFIX} Exception: #{exception.inspect}" }
            end

            sleep_interval = interval - (Concurrent.monotonic_time - start)
            sleep sleep_interval if sleep_interval.positive?
          end
        end

        private

        def forked?
          pid != Process.pid
        end

        def ensure_worker_running
          # Return early if thread is alive and avoid the mutex lock and unlock.
          return if thread_alive?

          # If another thread is starting worker thread, then return early so this
          # thread can enqueue and move on with life.
          return unless mutex.try_lock

          begin
            return if thread_alive?
            @thread = Thread.new { run }
            logger.debug { "#{PREFIX} Worker thread [#{@thread.object_id}] started" }
          ensure
            mutex.unlock
          end
        end

        def thread_alive?
          @thread && @thread.alive?
        end

        def reset
          @pid = Process.pid
          mutex.unlock if mutex.locked?
        end
      end
    end
  end
end
