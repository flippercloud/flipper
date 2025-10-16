require 'set'
require 'redis'
require 'flipper'
require 'flipper/adapters/redis_shared/methods'

module Flipper
  module Adapters
    class Redis
      include ::Flipper::Adapter
      include ::Flipper::Adapters::RedisShared

      attr_reader :key_prefix

      def features_key
        "#{key_prefix}flipper_features"
      end

      def key_for(feature_name)
        "#{key_prefix}#{feature_name}"
      end

      # Public: Initializes a Redis flipper adapter.
      #
      # client - The Redis client to use.
      # key_prefix - an optional prefix with which to namespace
      #              flipper's Redis keys
      def initialize(client, key_prefix: nil)
        @client = client
        @key_prefix = key_prefix
        @sadd_returns_boolean = with_connection do |conn|
          conn.class.respond_to?(:sadd_returns_boolean) && conn.class.sadd_returns_boolean
        end
      end

      # Public: The set of known features.
      def features
        read_feature_keys
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        if redis_sadd_returns_boolean?
          with_connection { |conn| conn.sadd? features_key, feature.key }
        else
          with_connection { |conn| conn.sadd features_key, feature.key }
        end
        true
      end

      # Public: Removes a feature from the set of known features.
      def remove(feature)
        if redis_sadd_returns_boolean?
          with_connection { |conn| conn.srem? features_key, feature.key }
        else
          with_connection { |conn| conn.srem features_key, feature.key }
        end
        with_connection { |conn| conn.del key_for(feature.key) }
        true
      end

      # Public: Clears the gate values for a feature.
      def clear(feature)
        with_connection { |conn| conn.del key_for(feature.key) }
        true
      end

      # Public: Gets the values for all gates for a given feature.
      #
      # Returns a Hash of Flipper::Gate#key => value.
      def get(feature)
        doc = doc_for(feature)
        result_for_feature(feature, doc)
      end

      def get_multi(features)
        read_many_features(features)
      end

      def get_all(**kwargs)
        features = read_feature_keys.map { |key| Flipper::Feature.new(key, self) }
        read_many_features(features)
      end

      # Public: Enables a gate for a given thing.
      #
      # feature - The Flipper::Feature for the gate.
      # gate - The Flipper::Gate to enable.
      # thing - The Flipper::Type being enabled for the gate.
      #
      # Returns true.
      def enable(feature, gate, thing)
        feature_key = key_for(feature.key)
        case gate.data_type
        when :boolean
          clear(feature)
          with_connection { |conn| conn.hset feature_key, gate.key, thing.value.to_s }
        when :integer
          with_connection { |conn| conn.hset feature_key, gate.key, thing.value.to_s }
        when :set
          with_connection { |conn| conn.hset feature_key, to_field(gate, thing), 1 }
        when :json
          with_connection { |conn| conn.hset feature_key, gate.key, Typecast.to_json(thing.value) }
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
        feature_key = key_for(feature.key)
        case gate.data_type
        when :boolean
          with_connection { |conn| conn.del feature_key }
        when :integer
          with_connection { |conn| conn.hset feature_key, gate.key, thing.value.to_s }
        when :set
          with_connection { |conn| conn.hdel feature_key, to_field(gate, thing) }
        when :json
          with_connection { |conn| conn.hdel feature_key, gate.key }
        else
          unsupported_data_type gate.data_type
        end

        true
      end

      private

      def redis_sadd_returns_boolean?
        @sadd_returns_boolean
      end

      def read_many_features(features)
        docs = docs_for(features)
        result = {}
        features.zip(docs) do |feature, doc|
          result[feature.key] = result_for_feature(feature, doc)
        end
        result
      end

      def read_feature_keys
        with_connection { |conn| conn.smembers(features_key).to_set }
      end

      # Private: Gets a hash of fields => values for the given feature.
      #
      # Returns a Hash of fields => values.
      def doc_for(feature, pipeline: nil)
        if pipeline
          pipeline.hgetall(key_for(feature.key))
        else
          with_connection { |conn| conn.hgetall(key_for(feature.key)) }
        end
      end

      def docs_for(features)
        with_connection do |conn|
          conn.pipelined do |pipeline|
            features.each do |feature|
              doc_for(feature, pipeline: pipeline)
            end
          end
        end
      end

      def result_for_feature(feature, doc)
        result = {}
        fields = doc.keys

        feature.gates.each do |gate|
          result[gate.key] =
            case gate.data_type
            when :boolean, :integer
              doc[gate.key.to_s]
            when :set
              fields_to_gate_value fields, gate
            when :json
              value = doc[gate.key.to_s]
              Typecast.from_json(value)
            else
              unsupported_data_type gate.data_type
            end
        end

        result
      end

      # Private: Converts gate and thing to hash key.
      def to_field(gate, thing)
        "#{gate.key}/#{thing.value}"
      end

      # Private: Returns a set of values given an array of fields and a gate.
      #
      # Returns a Set of the values enabled for the gate.
      def fields_to_gate_value(fields, gate)
        regex = %r{^#{Regexp.escape(gate.key.to_s)}/}
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

Flipper.configure do |config|
  config.adapter do
    client = Redis.new(url: ENV["FLIPPER_REDIS_URL"] || ENV["REDIS_URL"] || "redis://localhost:6379")
    Flipper::Adapters::Redis.new(client)
  end
end
