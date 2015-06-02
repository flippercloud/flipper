require 'set'
require 'redis'
require 'flipper'

module Flipper
  module Adapters
    class Redis
      include Flipper::Adapter

      # Private: The key that stores the set of known features.
      FeaturesKey = :flipper_features

      # Public: The name of the adapter.
      attr_reader :name

      # Public: Initializes a Redis flipper adapter.
      #
      # client - The Redis client to use. Feel free to namespace it.
      def initialize(client, options = {})
        @namespace = options.fetch(:namespace)
        @client = client
        @name = :redis
      end

      # Public: The set of known features.
      def features
        @client.smembers(FeaturesKey).to_set
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        @client.sadd FeaturesKey, namespaced_key(feature)
        true
      end

      # Public: Removes a feature from the set of known features.
      def remove(feature)
        @client.multi do
          @client.srem FeaturesKey, namespaced_key(feature)
          @client.del namespaced_key(feature)
        end
        true
      end

      # Public: Clears the gate values for a feature.
      def clear(feature)
        @client.del namespaced_key(feature)
        true
      end

      # Public: Gets the values for all gates for a given feature.
      #
      # Returns a Hash of Flipper::Gate#key => value.
      def get(feature)
        result = {}
        doc = doc_for(feature)
        fields = doc.keys

        feature.gates.each do |gate|
          result[gate.key] = case gate.data_type
          when :boolean, :integer
            doc[gate.key.to_s]
          when :set
            fields_to_gate_value fields, gate
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
          @client.hset namespaced_key(feature), gate.key, thing.value.to_s
        when :set
          @client.hset namespaced_key(feature), to_field(gate, thing), 1
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
          @client.del namespaced_key(feature)
        when :integer
          @client.hset namespaced_key(feature), gate.key, thing.value.to_s
        when :set
          @client.hdel namespaced_key(feature), to_field(gate, thing)
        else
          unsupported_data_type gate.data_type
        end

        true
      end

      # Private: Gets a hash of fields => values for the given feature.
      #
      # Returns a Hash of fields => values.
      def doc_for(feature)
        @client.hgetall(namespaced_key(feature))
      end

      # Private: Converts gate and thing to hash key.
      def to_field(gate, thing)
        "#{gate.key}/#{thing.value}"
      end

      def namespaced_key(feature)
        if @namespace
          @namespace + ':' + feature.key
        else
          feature.key
        end
      end

      # Private: Returns a set of values given an array of fields and a gate.
      #
      # Returns a Set of the values enabled for the gate.
      def fields_to_gate_value(fields, gate)
        regex = /^#{Regexp.escape(gate.key.to_s)}\//
        keys = fields.grep(regex)
        values = keys.map { |key| key.split('/', 2).last }
        values.to_set
      end

      # Private
      def unsupported_data_type(data_type)
        raise "#{data_type} is not supported by this adapter"
      end
    end
  end
end
