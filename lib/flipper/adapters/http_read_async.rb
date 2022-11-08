require 'flipper'
require 'flipper/adapters/http'
require 'flipper/adapters/memory'
require 'flipper/adapters/http_read_async/worker'
require 'thread'

module Flipper
  module Adapters
    class HttpReadAsync
      include Flipper::Adapter

      attr_reader :name

      def initialize(options = {})
        @name = :http_async
        @memory_adapter = Memory.new
        @mutex = Mutex.new

        # let's not start cold since cloud is configured with a local adapter,
        # instead we can initially populate the memory adapter with the
        # local adapter
        if adapter = options[:start_with]
          @memory_adapter.import(adapter)
        end

        @http_adapter = Http.new(options)
        @interval = options.fetch(:interval, 10)

        # setup the worker and default interval to top level interval if not
        # set, setting interval in worker options takes precendence
        worker_options = options[:worker] || {}
        worker_options[:interval] ||= @interval
        @worker = Worker.new(worker_options) {
          adapter = Memory.new
          adapter.import(@http_adapter)
          # lock when updating the memory adapter in the main thread
          @mutex.synchronize { @memory_adapter.import(adapter) }
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
