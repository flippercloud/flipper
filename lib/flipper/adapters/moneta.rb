require 'moneta'

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
        read_feature_keys
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        set_add(FEATURES_KEY, feature.key)
        true
      end

      # Public: Removes a feature from the set of known features and clears
      # all the values for the feature.
      def remove(feature)
        set_delete(FEATURES_KEY, feature.key)
        clear(feature)
        true
      end

      # Public: Clears all the gate values for a feature.
      def clear(feature)
        feature.gates.each do |gate|
          delete key(feature, gate)
        end
        true
      end

      # Public
      def get(feature)
        read_feature(feature)
      end

      def get_multi(features)
        read_many_features(features)
      end

      def get_all
        features = read_feature_keys.map do |key|
          Flipper::Feature.new(key, self)
        end
        read_many_features(features)
      end

      # Public
      def enable(feature, gate, thing)
        case gate.data_type
        when :boolean, :integer
          write key(feature, gate), thing.value.to_s
        when :set
          set_add key(feature, gate), thing.value.to_s
        else
          raise "#{gate} is not supported by this adapter yet"
        end

        true
      end

      # Public
      def disable(feature, gate, thing)
        case gate.data_type
        when :boolean
          clear(feature)
        when :integer
          write key(feature, gate), thing.value.to_s
        when :set
          set_delete key(feature, gate), thing.value.to_s
        else
          raise "#{gate} is not supported by this adapter yet"
        end
        true
      end

      private

      # Private
      def read_feature_keys
        set_members(FEATURES_KEY)
      end

      # Private
      def key(feature, gate)
        "feature/#{feature.key}/#{gate.key}"
      end

      # Private
      def read_many_features(features)
        result = {}
        features.each do |feature|
          result[feature.key] = read_feature(feature)
        end
        result
      end

      # Private
      def read_feature(feature)
        result = {}

        feature.gates.each do |gate|
          result[gate.key] =
            case gate.data_type
            when :boolean, :integer
              read key(feature, gate)
            when :set
              set_members key(feature, gate)
            else
              raise "#{gate} is not supported by this adapter yet"
            end
        end
        result
      end

      # Private
      def read(key)
        @moneta[key.to_s]
      end

      # Private
      def write(key, value)
        @moneta[key.to_s] = value.to_s
      end

      # Private
      def delete(key)
        @moneta.delete(key.to_s)
      end

      # Private
      def set_add(key, value)
        @moneta[key.to_s] = @moneta.fetch(key.to_s) { Set.new }.add(value.to_s)
      end

      # Private
      def set_delete(key, value)
        @moneta[key.to_s] = @moneta.fetch(key.to_s) { Set.new }.delete(value.to_s)
      end

      # Private
      def set_members(key)
        @moneta.fetch(key.to_s) { Set.new }
      end
    end
  end
end
