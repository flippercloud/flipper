require 'set'

module Flipper
  module Adapters
    class Memory
      include Flipper::Adapter

      FeaturesKey = :flipper_features

      # Public: The name of the adapter.
      attr_reader :name

      # Public
      def initialize(source = nil)
        @source = source || {}
        @name = :memory
      end

      # Public
      def get(feature)
        result = {}

        feature.gates.each do |gate|
          result[gate.key] = case gate.data_type
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

      # Public: Adds a feature to the set of known features.
      def add(feature)
        features.add(feature.name.to_s)
        true
      end

      # Public: Clears all the gate values for a feature.
      def clear(feature)
        feature.gates.each do |gate|
          delete key(feature, gate)
        end
      end

      # Public: Removes a feature from the set of known features and clears
      # all the values for the feature.
      def remove(feature)
        features.delete(feature.name.to_s)
        clear(feature)
        true
      end

      # Public: The set of known features.
      def features
        set_members(FeaturesKey)
      end

      def inspect
        attributes = [
          "name=:memory",
          "source=#{@source.inspect}",
        ]
        "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
      end

      # private
      def key(feature, gate)
        "#{feature.key}/#{gate.key}"
      end

      # Private
      def read(key)
        @source[key.to_s]
      end

      # Private
      def write(key, value)
        @source[key.to_s] = value.to_s
      end

      # Private
      def delete(key)
        @source.delete(key.to_s)
      end

      # Private
      def set_add(key, value)
        ensure_set_initialized(key)
        @source[key.to_s].add(value.to_s)
      end

      # Private
      def set_delete(key, value)
        ensure_set_initialized(key)
        @source[key.to_s].delete(value.to_s)
      end

      # Private
      def set_members(key)
        ensure_set_initialized(key)
        @source[key.to_s]
      end

      # Private
      def ensure_set_initialized(key)
        @source[key.to_s] ||= Set.new
      end
    end
  end
end
