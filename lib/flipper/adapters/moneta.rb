require 'moneta'

module Flipper
  module Adapters
    # Public: Adapter that stores features in any Moneta-backed store.
    #
    # WARNING: This adapter is NOT safe for concurrent writes to the same
    # feature. Set-based gates (actors, groups, percentage of actors) are
    # updated with a non-atomic read-modify-write: the current value is read
    # from the store, mutated in Ruby, and written back with no lock or
    # transaction. Two writers racing on the same feature (e.g. enabling two
    # different actors) will each read the same set and the second write will
    # clobber the first, silently dropping one of the changes. Unlike the
    # Memory and PStore adapters, Moneta provides no portable atomic primitive
    # to guard against this. If you need concurrent writes to a shared store,
    # prefer a native adapter such as ActiveRecord or Redis.
    class Moneta
      include ::Flipper::Adapter

      FEATURES_KEY = :flipper_features

      # Public
      def initialize(moneta)
        @moneta = moneta
      end

      # Public:  The set of known features
      def features
        moneta[FEATURES_KEY] || Set.new
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        moneta[FEATURES_KEY] = features << feature.key.to_s
        true
      end

      # Public: Removes a feature from the set of known features and clears
      # all the values for the feature.
      def remove(feature)
        moneta[FEATURES_KEY] = features.delete(feature.key.to_s)
        moneta.delete(key(feature.key))
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
        default_config.merge(moneta[key(feature.key)].to_h)
      end

      # Public: Enables a gate for a given thing.
      #
      # feature - The Flipper::Feature for the gate.
      # gate - The Flipper::Gate to enable.
      # thing - The Flipper::Type being enabled for the gate.
      #
      # Returns true.
      def enable(feature, gate, thing)
        case gate.data_type
        when :boolean
          clear(feature)
          result = get(feature)
          result[gate.key] = thing.value.to_s
          moneta[key(feature.key)] = result
        when :integer
          result = get(feature)
          result[gate.key] = thing.value.to_s
          moneta[key(feature.key)] = result
        when :set
          result = get(feature)
          result[gate.key] << thing.value.to_s
          moneta[key(feature.key)] = result
        when :json
          result = get(feature)
          result[gate.key] = thing.value
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
          clear(feature)
        when :integer
          result = get(feature)
          result[gate.key] = thing.value.to_s
          moneta[key(feature.key)] = result
        when :set
          result = get(feature)
          result[gate.key] = result[gate.key].delete(thing.value.to_s)
          moneta[key(feature.key)] = result
        when :json
          result = get(feature)
          result[gate.key] = nil
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
