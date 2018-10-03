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
