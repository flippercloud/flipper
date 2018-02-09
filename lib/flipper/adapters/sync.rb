module Flipper
  module Adapters
    class Sync
      include ::Flipper::Adapter

      # Public: The name of the adapter.
      attr_reader :name

      def initialize(local, remote)
        @local = local
        @remote = remote
        @name = :sync
      end

      def features
        @local.features
      end

      def add(feature)
        result = @remote.add(feature)
        @local.add(feature)
        result
      end

      def remove(feature)
        result = @remote.remove(feature)
        @local.remove(feature)
        result
      end

      def clear(feature)
        result = @remote.clear(feature)
        @local.clear(feature)
        result
      end

      def get(feature)
        @local.get(feature)
      end

      def get_multi(features)
        @local.get_multi(features)
      end

      def get_all
        @local.get_all
      end

      def enable(feature, gate, thing)
        result = @remote.enable(feature, gate, thing)
        @local.enable(feature, gate, thing)
        result
      end

      def disable(feature, gate, thing)
        result = @remote.disable(feature, gate, thing)
        @local.disable(feature, gate, thing)
        result
      end
    end
  end
end
