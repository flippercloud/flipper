require 'flipper'

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

      # Public: Get all features and gate values in one call. Defaults to one call
      # to features and another to get_multi. Feel free to override per adapter to
      # make this more efficient.
      def get_all
        instances = features.map { |key| build_feature(key) }
        get_multi(instances)
      end

      # Public: Get multiple features in one call. Defaults to one get per
      # feature. Feel free to override per adapter to make this more efficient and
      # reduce network calls.
      def get_multi(features)
        result = {}
        features.each do |feature|
          result[feature.key] = get(feature)
        end
        result
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
