require "flipper/adapter"
require "flipper/typecast"

module Flipper
  module Adapters
    # Public: Adapter for storing everything in memory.
    # Useful for tests/specs.
    class Memory
      include ::Flipper::Adapter

      # Private: Shared frozen config for unknown features. Gate values
      # returned by get are treated as read-only.
      DEFAULT_CONFIG = default_config.each_value(&:freeze).freeze

      # Public
      def initialize(source = nil, threadsafe: true)
        @source = Typecast.features_hash(source)
        @lock = Mutex.new if threadsafe
        @sync_version = nil
      end

      # Public
      def sync_version
        synchronize { @sync_version }
      end

      # Public
      def sync_version=(version)
        synchronize { @sync_version = version }
      end

      # Public: The set of known features.
      def features
        synchronize { @source.keys }.to_set
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        synchronize { @source[feature.key] ||= default_config }
        true
      end

      # Public: Removes a feature from the set of known features and clears
      # all the values for the feature.
      def remove(feature)
        synchronize { @source.delete(feature.key) }
        true
      end

      # Public: Clears all the gate values for a feature.
      def clear(feature)
        synchronize { @source[feature.key] = default_config }
        true
      end

      # Public
      def get(feature)
        synchronize { @source[feature.key] } || DEFAULT_CONFIG
      end

      def get_multi(features)
        synchronize do
          result = {}
          features.each do |feature|
            result[feature.key] = @source[feature.key] || DEFAULT_CONFIG
          end
          result
        end
      end

      def get_all(**kwargs)
        synchronize { Typecast.features_hash(@source) }
      end

      # Public
      def enable(feature, gate, thing)
        synchronize do
          # Write a copy, because get hands out the stored hash and its sets.
          gates = (@source[feature.key] || default_config).dup

          case gate.data_type
          when :boolean
            gates = default_config
            gates[gate.key] = thing.value.to_s
          when :integer
            gates[gate.key] = thing.value.to_s
          when :set
            gates[gate.key] = gates[gate.key] | [thing.value.to_s]
          when :json
            gates[gate.key] = thing.value
          else
            raise "#{gate} is not supported by this adapter yet"
          end

          @source[feature.key] = gates
          true
        end
      end

      # Public
      def disable(feature, gate, thing)
        synchronize do
          gates = (@source[feature.key] || default_config).dup

          case gate.data_type
          when :boolean
            gates = default_config
          when :integer
            gates[gate.key] = thing.value.to_s
          when :set
            gates[gate.key] = gates[gate.key] - [thing.value.to_s]
          when :json
            gates.delete(gate.key)
          else
            raise "#{gate} is not supported by this adapter yet"
          end

          @source[feature.key] = gates
          true
        end
      end

      # Public
      def inspect
        attributes = [
          'name=:memory',
          "source=#{@source.inspect}",
        ]
        "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
      end

      # Public: a more efficient implementation of import for this adapter.
      # Keeps the current flags if the source's are an older sync version.
      def import(source)
        adapter = self.class.from(source)
        get_all = Typecast.features_hash(adapter.get_all)
        version = adapter.sync_version

        synchronize do
          unless version&.older_than?(@sync_version)
            @source.replace(get_all)
            @sync_version = version if version
          end
        end

        true
      end

      private

      def synchronize(&block)
        if @lock
          @lock.synchronize(&block)
        else
          block.call
        end
      end
    end
  end
end
