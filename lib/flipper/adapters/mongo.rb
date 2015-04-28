require 'set'
require 'flipper'
require 'mongo'

module Flipper
  module Adapters
    class Mongo
      include Flipper::Adapter

      # Private: The key that stores the set of known features.
      FeaturesKey = :flipper_features

      # Public: The name of the adapter.
      attr_reader :name

      def initialize(collection)
        @collection = collection
        @name = :mongo
      end

      # Public: The set of known features.
      def features
        find(FeaturesKey).fetch('features') { Set.new }.to_set
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        update FeaturesKey, '$addToSet' => {'features' => feature.key}
        true
      end

      # Public: Removes a feature from the set of known features.
      def remove(feature)
        update FeaturesKey, '$pull' => {'features' => feature.key}
        clear feature
        true
      end

      # Public: Clears all the gate values for a feature.
      def clear(feature)
        delete feature.key
        true
      end

      # Public: Gets the values for all gates for a given feature.
      #
      # Returns a Hash of Flipper::Gate#key => value.
      def get(feature)
        result = {}
        doc = find(feature.key)

        feature.gates.each do |gate|
          result[gate.key] = case gate.data_type
          when :boolean, :integer
            doc[gate.key.to_s]
          when :set
            doc.fetch(gate.key.to_s) { Set.new }.to_set
          else
            unsupported_data_type gate.data_type
          end
        end

        result
      end

      # Public: Enables a gate for a given thing.
      #
      # feature - The Flipper::Feature for the gate.
      # gate - The Flipper::Gate to disable.
      # thing - The Flipper::Type being disabled for the gate.
      #
      # Returns true.
      def enable(feature, gate, thing)
        case gate.data_type
        when :boolean, :integer
          update feature.key, '$set' => {
            gate.key.to_s => thing.value.to_s,
          }
        when :set
          update feature.key, '$addToSet' => {
            gate.key.to_s => thing.value.to_s,
          }
        else
          unsupported_data_type gate.data_type
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
          delete feature.key
        when :integer
          update feature.key, '$set' => {gate.key.to_s => thing.value.to_s}
        when :set
          update feature.key, '$pull' => {gate.key.to_s => thing.value.to_s}
        else
          unsupported_data_type gate.data_type
        end

        true
      end

      # Private
      def unsupported_data_type(data_type)
        raise "#{data_type} is not supported by this adapter"
      end

      # Private
      def find(key)
        @collection.find(criteria(key)).limit(1).first || {}
      end

      # Private
      def update(key, updates)
        options = {:upsert => true}
        @collection.find(criteria(key)).update_one(updates, options)
      end

      # Private
      def delete(key)
        @collection.find(criteria(key)).delete_one
      end

      # Private
      def criteria(key)
        {:_id => key.to_s}
      end
    end
  end
end
