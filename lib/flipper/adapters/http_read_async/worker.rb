require 'logger'

module Flipper
  module Adapters
    class HttpReadAsync
      class Worker
        PREFIX = "[flipper http read async adapter]".freeze

        attr_reader :thread, :pid, :mutex, :logger, :interval

        def initialize(options = {}, &block)
          @thread = nil
          @pid = Process.pid
          @mutex = Mutex.new
          @logger = options.fetch(:logger) { Logger.new(STDOUT) }
          @interval = options.fetch(:interval, 10).to_f

          if @interval < 1
            raise ArgumentError, "interval must be greater than or equal to 1 but was #{@interval}"
          end

          @start_automatically = options.fetch(:start_automatically, true)
          @block = block

          if options.fetch(:shutdown_automatically, true)
            at_exit { stop }
          end
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
            logger.debug { "#{PREFIX} Sleeping for #{interval} seconds" }
            sleep interval

            begin
              logger.debug { "#{PREFIX} Making a checkity checkity" }
              @block.call
            rescue => exception
              logger.debug { "#{PREFIX} Exception: #{exception.inspect}" }
            end
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
