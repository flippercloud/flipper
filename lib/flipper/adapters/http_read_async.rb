require 'flipper'
require 'flipper/adapters/http'
require 'flipper/adapters/memory'

module Flipper
  module Adapters
    class HttpReadAsync
      include Flipper::Adapter

      attr_reader :name

      require 'thread'
      require 'logger'

      class Worker
        PREFIX = "[flipper http read async adapter]".freeze

        attr_reader :thread, :pid, :mutex, :logger, :interval

        def initialize(options = {}, &block)
          @thread = nil
          @pid = Process.pid
          @mutex = Mutex.new
          @logger = options.fetch(:logger) { Logger.new(STDOUT) }
          @interval = options.fetch(:interval, 10)
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
          logger.info { "#{PREFIX} Stopping worker" }
          @thread&.kill
        end

        def run
          loop do
            logger.info { "#{PREFIX} Sleeping for #{interval} seconds" }
            sleep interval

            begin
              logger.info { "#{PREFIX} Making a checkity checkity" }
              @block.call
            rescue => exception
              # log this or something
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

      def initialize(options = {})
        @memory_adapter = Memory.new
        @http_adapter = Http.new(options)
        @mutex = Mutex.new
        @name = :http_async
        @worker = Worker.new(options[:worker] || {}) {
          adapter = Memory.new
          adapter.import(@http_adapter)
          @mutex.synchronize {
            @memory_adapter.import(adapter)
          }
        }
        @worker.start
      end

      def get(feature)
        @worker.start
        @mutex.synchronize { @memory_adapter.get(feature) }
      end

      def get_multi(features)
        @worker.start
        @mutex.synchronize { @memory_adapter.get_multi(features) }
      end

      def get_all
        @worker.start
        @mutex.synchronize { @memory_adapter.get_all }
      end

      def features
        @worker.start
        @mutex.synchronize { @memory_adapter.features }
      end

      def add(feature)
        @worker.start
        @http_adapter.add(feature).tap {
          @mutex.synchronize { @memory_adapter.add(feature) }
        }
      end

      def remove(feature)
        @worker.start
        @http_adapter.remove(feature).tap {
          @mutex.synchronize { @memory_adapter.remove(feature) }
        }
      end

      def enable(feature, gate, thing)
        @worker.start
        @http_adapter.enable(feature, gate, thing).tap {
          @mutex.synchronize { @memory_adapter.enable(feature, gate, thing) }
        }
      end

      def disable(feature, gate, thing)
        @worker.start
        @http_adapter.disable(feature, gate, thing).tap {
          @mutex.synchronize { @memory_adapter.disable(feature, gate, thing) }
        }
      end

      def clear(feature)
        @worker.start
        @http_adapter.clear(feature).tap {
          @mutex.synchronize { @memory_adapter.clear(feature) }
        }
      end
    end
  end
end
