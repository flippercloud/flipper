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
        rollout_feature = @rollout.get(feature.key)
        return default_config if rollout_feature.nil?

        boolean = nil
        groups = Set.new(rollout_feature.groups)
        actors = Set.new(rollout_feature.users)

        percentage_of_actors = case rollout_feature.percentage
                               when 100
                                 boolean = true
                                 groups = Set.new
                                 actors = Set.new
                                 nil
                               when 0
                                 nil
                               else
                                 rollout_feature.percentage
                               end

        {
          boolean: boolean,
          groups: groups,
          actors: actors,
          percentage_of_actors: percentage_of_actors,
          percentage_of_time: nil,
        }
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
