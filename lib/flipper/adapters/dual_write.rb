module Flipper
  module Adapters
    class DualWrite
      include ::Flipper::Adapter

      attr_reader :local, :remote

      # Public: Build a new sync instance.
      #
      # local - The local flipper adapter that should serve reads.
      # remote - The remote flipper adapter that writes should go to first (in
      #          addition to the local adapter).
      def initialize(local, remote, options = {})
        @local = local
        @remote = remote
        @synchronization_state = options[:synchronization_state]
      end

      def adapter_stack
        "#{name}(local: #{@local.adapter_stack}, remote: #{@remote.adapter_stack})"
      end

      def features
        @local.features
      end

      def get(feature)
        @local.get(feature)
      end

      def get_multi(features)
        @local.get_multi(features)
      end

      def get_all(**kwargs)
        @local.get_all(**kwargs)
      end

      def add(feature)
        synchronize { @remote.add(feature).tap { @local.add(feature) } }
      end

      def remove(feature)
        synchronize { @remote.remove(feature).tap { @local.remove(feature) } }
      end

      def clear(feature)
        synchronize { @remote.clear(feature).tap { @local.clear(feature) } }
      end

      def enable(feature, gate, thing)
        synchronize do
          @remote.enable(feature, gate, thing).tap do
            @local.enable(feature, gate, thing)
          end
        end
      end

      def disable(feature, gate, thing)
        synchronize do
          @remote.disable(feature, gate, thing).tap do
            @local.disable(feature, gate, thing)
          end
        end
      end

      private

      def synchronize(&block)
        if @synchronization_state
          @synchronization_state.synchronize_write(&block)
        else
          yield
        end
      end
    end
  end
end
