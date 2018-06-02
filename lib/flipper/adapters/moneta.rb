require 'moneta'

module Flipper
  module Adapters
    class Moneta
      include ::Flipper::Adapter

      FEATURES_KEY = :flipper_features

      # Public: The name of the adapter.
      attr_reader :name

      # Public
      def initialize(moneta)
        @moneta = moneta
        @name = :moneta
      end

      # Public:  The set of known features
      def features
        moneta[FEATURES_KEY] || Set.new
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        moneta[FEATURES_KEY] = (moneta[FEATURES_KEY] || Set.new) << feature.key.to_s
        true
      end

      # Public: Removes a feature from the set of known features and clears
      # all the values for the feature.
      def remove(feature)
        features = moneta[FEATURES_KEY] || Set.new
        features.delete(feature.key.to_s)
        moneta[FEATURES_KEY] = features
        moneta[key(feature.key)] = default_config
        true
      end

      # Public: Clears all the gate values for a feature.
      def clear(feature)
        moneta[key(feature.key)] = default_config
        true
      end

      # Public: Gets the values for all gates for a given feature.
      #
      # Returns a Hash of Flipper::Gate#key => value.
      def get(feature)
        moneta[key(feature.key)] || default_config
      end

      # Public
      def get_multi(features)
        result = {}
        features.each do |feature|
          result[feature.key] = default_config.merge(moneta[key(feature.key)].to_h)
        end
        result
      end

      # Public
      def get_all
        result = {}
        moneta[FEATURES_KEY].each do |feature_key|
          result[feature_key] = default_config.merge(moneta[key(feature_key)].to_h)
        end
        result
      end

      # Public: Enables a gate for a given thing.
      #
      # feature - The Flipper::Feature for the gate.
      # gate - The Flipper::Gate to disable.
      # thing - The Flipper::Type being enabled for the gate.
      #
      # Returns true.
      def enable(feature, gate, thing)
        case gate.data_type
        when :boolean, :integer
          result = moneta[key(feature.key)] || {}
          result[gate.key] = thing.value.to_s
          moneta[key(feature.key)] = result
        when :set
          result = moneta[key(feature.key)] || {}
          result[gate.key] ||= Set.new
          result[gate.key] << thing.value.to_s
          moneta[key(feature.key)] = result
        end
        true
      end

      # Public: Disables a gate for a given thing.
      #
      # feature - The Flipper::Feature for the gate.
      # gate - The Flipper::Gate to disable.
      # thing - The Flipper::Type being disabled for the gate.
      #
      # Returns true.
      def disable(feature, gate, thing)
        case gate.data_type
        when :boolean
          moneta[key(feature.key)] = default_config
        when :integer
          result = moneta[key(feature.key)] || {}
          result[gate.key] = thing.value.to_s
          moneta[key(feature.key)] = result
        when :set
          result = moneta[key(feature.key)]
          result[gate.key] = result[gate.key].delete(thing.value.to_s) if result[gate.key]
          moneta[key(feature.key)] = result
        end
        true
      end

      private

      def key(feature_key)
        "#{FEATURES_KEY}/#{feature_key}"
      end

      attr_reader :moneta
    end
  end
end
