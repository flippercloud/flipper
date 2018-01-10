require 'moneta'
require 'pry'

module Flipper
  module Adapters
    class Moneta
      include ::Flipper::Adapter

      FEATURES_KEY = :features

      # Public: The name of the adapter.
      attr_reader :name

      # Public
      def initialize(moneta)
        @moneta = moneta
        @name = :moneta
      end

      def features
        moneta[:features] || Set.new
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        moneta[:features] = moneta[:features] || Set.new
        moneta[:features] = moneta[:features] << feature.key.to_s
        true
      end

      # Public: Removes a feature from the set of known features and clears
      # all the values for the feature.
      def remove(feature)
        moneta[:features] = moneta[:features] || Set.new
        features = moneta[:features]
        features.delete(feature.key.to_s)
        moneta[:features] = features
        moneta[feature.key] = default_config
        true
      end

      # Public: Clears all the gate values for a feature.
      def clear(feature)
        moneta[feature.key] = default_config
        true
      end

      # Public
      def get(feature)
        moneta[feature.key] || default_config
      end

      def get_multi(features)
        h = {}
        features.each do |feature|
          h[feature.key] = default_config.merge(moneta[feature.key].to_h)
        end
        h
      end

      def get_all
        h = {}
        moneta[:features].each do |feature_key|
          h[feature_key] = default_config.merge(moneta[feature_key].to_h)
        end
        h
      end

      # Public
      def enable(feature, gate, thing)
        case gate.data_type
        when :boolean, :integer
          the_feature = moneta[feature.key] || {}
          the_feature[gate.key] = thing.value.to_s
          moneta[feature.key] = the_feature
        when :set
          the_feature = moneta[feature.key] || {}
          if the_feature[gate.key]
            the_feature[gate.key] << thing.value.to_s
            moneta[feature.key] = the_feature
          else
            the_feature[gate.key] = Set.new
            the_feature[gate.key] << thing.value.to_s
            moneta[feature.key] = the_feature
          end
        end
        true
      end

      # Public
      def disable(feature, gate, thing)
        #binding.pry if thing.value.to_s == 0.to_s
        case gate.data_type
        when :boolean
          moneta[feature.key] = default_config
        when :integer
          the_feature = moneta[feature.key] || default_config
          the_feature[gate.key] = thing.value.to_s
          moneta[feature.key] = the_feature
        when :set
          the_feature = moneta[feature.key]
          if the_feature[gate.key]
            the_feature[gate.key] = the_feature[gate.key].delete(thing.value.to_s)
          end
          moneta[feature.key] = the_feature
        end
        true
      end

      private

      attr_reader :moneta
    end
  end
end
