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
        update FeaturesKey, '$addToSet' => {'features' => feature.key}
        true
      end

      def remove(feature)
        update FeaturesKey, '$pull' => {'features' => feature.key}
        clear feature
        true
      end

      def clear(feature)
        delete feature.key
        true
      end

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
          update feature.key, '$set' => {gate.key.to_s => thing.value.to_s}
        when :set
          update feature.key, '$pull' => {gate.key.to_s => thing.value.to_s}
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
        @collection.find(criteria(key)).limit(1).first || {}
      end

      def update(key, updates)
        options = {:upsert => true}
        @collection.find(criteria(key)).update_one(updates, options)
      end

      def delete(key)
        @collection.find(criteria(key)).delete_one
      end

      def criteria(key)
        {:_id => key.to_s}
      end
    end
  end
end
