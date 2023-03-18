require "flipper/adapter"
require "flipper/typecast"
require 'concurrent/atomic/read_write_lock'

module Flipper
  module Adapters
    # Public: Adapter for storing everything in memory.
    # Useful for tests/specs.
    class Memory
      include ::Flipper::Adapter

      FeaturesKey = :features

      # Public: The name of the adapter.
      attr_reader :name

      # Public
      def initialize(source = nil)
        @source = Typecast.features_hash(source)
        @name = :memory
        @lock = Concurrent::ReadWriteLock.new
      end

      # Public: The set of known features.
      def features
        @lock.with_read_lock { @source.keys }.to_set
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        @lock.with_write_lock { @source[feature.key] ||= default_config }
        true
      end

      # Public: Removes a feature from the set of known features and clears
      # all the values for the feature.
      def remove(feature)
        @lock.with_write_lock { @source.delete(feature.key) }
        true
      end

      # Public: Clears all the gate values for a feature.
      def clear(feature)
        @lock.with_write_lock { @source[feature.key] = default_config }
        true
      end

      # Public
      def get(feature)
        @lock.with_read_lock { @source[feature.key] } || default_config
      end

      def get_multi(features)
        @lock.with_read_lock do
          result = {}
          features.each do |feature|
            result[feature.key] = @source[feature.key] || default_config
          end
          result
        end
      end

      def get_all
        @lock.with_read_lock { Typecast.features_hash(@source) }
      end

      # Public
      def enable(feature, gate, thing)
        @lock.with_write_lock do
          @source[feature.key] ||= default_config

          case gate.data_type
          when :boolean
            @source[feature.key] = default_config
            @source[feature.key][gate.key] = thing.value.to_s
          when :integer
            @source[feature.key][gate.key] = thing.value.to_s
          when :set
            @source[feature.key][gate.key] << thing.value.to_s
          else
            raise "#{gate} is not supported by this adapter yet"
          end

          true
        end
      end

      # Public
      def disable(feature, gate, thing)
        @lock.with_write_lock do
          @source[feature.key] ||= default_config

          case gate.data_type
          when :boolean
            @source[feature.key] = default_config
          when :integer
            @source[feature.key][gate.key] = thing.value.to_s
          when :set
            @source[feature.key][gate.key].delete thing.value.to_s
          else
            raise "#{gate} is not supported by this adapter yet"
          end

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

      # Public: a more efficient implementation of import for this adapter
      def import(source)
        adapter = self.class.from(source)
        get_all = Typecast.features_hash(adapter.get_all)
        @lock.with_write_lock { @source.replace(get_all) }
        true
      end
    end
  end
end
