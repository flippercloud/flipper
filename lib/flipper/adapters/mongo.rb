require 'set'
require 'flipper'
require 'mongo'

module Flipper
  module Adapters
    class Mongo
      include ::Flipper::Adapter

      # Private: The key that stores the set of known features.
      FeaturesKey = :flipper_features

      # Public: The name of the adapter.
      attr_reader :name

      # Public: The name of the collection storing the feature data.
      attr_reader :collection

      def initialize(collection)
        @collection = collection
        @name = :mongo
      end

      # Public: The set of known features.
      def features
        read_feature_keys
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        update FeaturesKey, '$addToSet' => { 'features' => feature.key }
        true
      end

      # Public: Removes a feature from the set of known features.
      def remove(feature)
        update FeaturesKey, '$pull' => { 'features' => feature.key }
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
        doc = find(feature.key)
        result_for_feature(feature, doc)
      end

      def get_multi(features)
        read_many_features(features)
      end

      def get_all
        features = read_feature_keys.map { |key| Flipper::Feature.new(key, self) }
        read_many_features(features)
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
        when :boolean
          clear(feature)
          update feature.key, '$set' => {
            gate.key.to_s => thing.value.to_s,
          }
        when :integer
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
          update feature.key, '$set' => { gate.key.to_s => thing.value.to_s }
        when :set
          update feature.key, '$pull' => { gate.key.to_s => thing.value.to_s }
        else
          unsupported_data_type gate.data_type
        end

        true
      end

      private

      def read_feature_keys
        find(FeaturesKey).fetch('features') { Set.new }.to_set
      end

      def read_many_features(features)
        docs = find_many(features.map(&:key))
        result = {}
        features.each do |feature|
          result[feature.key] = result_for_feature(feature, docs[feature.key])
        end
        result
      end

      # Private
      def unsupported_data_type(data_type)
        raise "#{data_type} is not supported by this adapter"
      end

      # Private
      def find(key)
        @collection.find(_id: key.to_s).limit(1).first || {}
      end

      def find_many(keys)
        docs = @collection.find(_id: { '$in' => keys }).to_a
        result = Hash.new { |hash, key| hash[key] = {} }
        docs.each do |doc|
          result[doc['_id']] = doc
        end
        result
      end

      # Private
      def update(key, updates)
        options = { upsert: true }
        @collection.find(_id: key.to_s).update_one(updates, options)
      end

      # Private
      def delete(key)
        @collection.find(_id: key.to_s).delete_one
      end

      def result_for_feature(feature, doc)
        result = {}
        feature.gates.each do |gate|
          result[gate.key] =
            case gate.data_type
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
    end
  end
end

Flipper.configure do |config|
  config.adapter do
    url = ENV["FLIPPER_MONGO_URL"] || ENV["MONGO_URL"]
    collection = ENV["FLIPPER_MONGO_COLLECTION"] || "flipper"

    unless url
      raise ArgumentError, "The MONGO_URL environment variable must be set. For example: mongodb://127.0.0.1:27017/flipper"
    end

    Flipper::Adapters::Mongo.new(Mongo::Client.new(url)[collection])
  end
end
