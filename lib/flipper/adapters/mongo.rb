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

      def initialize(collection)
        @collection = collection
        @name = :mongo
      end

      def features
        find(FeaturesKey).fetch('features') { Set.new }.to_set
      end

      def add(feature)
        update FeaturesKey, '$addToSet' => { 'features' => feature.key }
        true
      end

      def remove(feature)
        update FeaturesKey, '$pull' => { 'features' => feature.key }
        clear feature
        true
      end

      def clear(feature)
        delete feature.key
        true
      end

      def get(feature)
        doc = find(feature.key)
        result_for_feature(feature, doc)
      end

      def get_multi(features)
        docs = find_many(features.map(&:key))
        result = {}
        features.each do |feature|
          result[feature.key] = result_for_feature(feature, docs[feature.key])
        end
        result
      end

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

      def unsupported_data_type(data_type)
        raise "#{data_type} is not supported by this adapter"
      end

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

      def update(key, updates)
        options = { upsert: true }
        @collection.find(_id: key.to_s).update_one(updates, options)
      end

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
