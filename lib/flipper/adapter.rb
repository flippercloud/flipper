require "set"

module Flipper
  # Adding a module include so we have some hooks for stuff down the road
  module Adapter
    V1 = "1".freeze
    V2 = "2".freeze

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Public: Default config for a feature's gate values.
      def default_config
        {
          boolean: nil,
          groups: Set.new,
          actors: Set.new,
          percentage_of_actors: nil,
          percentage_of_time: nil,
        }
      end
    end

    def version
      V1
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

    # Public: Ensure that adapter is in sync with source adapter provided.
    #
    # Returns result of Synchronizer#call.
    def import(source_adapter)
      Adapters::Sync::Synchronizer.new(self, source_adapter, raise: true).call
    end

    # Public: Default config for a feature's gate values.
    def default_config
      self.class.default_config
    end

    def build_feature(feature_key)
      Flipper::Feature.new(feature_key, Flipper::Storage.new(self))
    end
  end
end

require "flipper/feature"
require "flipper/adapters/sync/synchronizer"
