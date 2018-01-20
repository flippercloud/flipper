require "flipper/errors"

module Flipper
  module Adapters
    class Rollout
      include Adapter

      class AdapterMethodNotSupportedError < Error
        def initialize(message = 'unsupported method called for import adapter')
          super(message)
        end
      end

      # Public: The name of the adapter.
      attr_reader :name

      def initialize(rollout)
        @rollout = rollout
        @name = :rollout
      end

      # Public: The set of known features.
      def features
        @rollout.features
      end

      # Public: Gets the values for all gates for a given feature.
      #
      # Returns a Hash of Flipper::Gate#key => value.
      def get(feature)
        if rollout_feature = @rollout.get(feature.key)
          percentage = rollout_feature.percentage.zero? ? nil : rollout_feature.percentage
          {
            boolean: nil,
            groups: Set.new(rollout_feature.groups),
            actors: Set.new(rollout_feature.users),
            percentage_of_actors: percentage,
            percentage_of_time: nil,
          }
        else
          default_config
        end
      end

      def get_multi(_features)
        raise AdapterMethodNotSupportedError
      end

      def get_all
        raise AdapterMethodNotSupportedError
      end

      def add(_feature)
        raise AdapterMethodNotSupportedError
      end

      def remove(_feature)
        raise AdapterMethodNotSupportedError
      end

      def clear(_feature)
        raise AdapterMethodNotSupportedError
      end

      def enable(_feature, _gate, _thing)
        raise AdapterMethodNotSupportedError
      end

      def disable(_feature, _gate, _thing)
        raise AdapterMethodNotSupportedError
      end

      def import(_source_adapter)
        raise AdapterMethodNotSupportedError
      end
    end
  end
end
