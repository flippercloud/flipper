require 'set'

module Flipper
  module Adapters
    class Memory
      # Public
      def initialize(source = nil)
        @source = source || {}
      end

      # Public
      def get(feature)
        result = {}

        feature.gates.each do |gate|
          result[gate] = case gate.data_type
          when :boolean
            read key(feature, gate)
          when :integer
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
      end

      # Public
      def disable(feature, gate, thing)
        case gate.data_type
        when :boolean
          feature.gates.each do |gate|
            delete key(feature, gate)
          end
        when :integer
          write key(feature, gate), 0
        when :set
          set_delete key(feature, gate), thing.value.to_s
        else
          raise "#{gate} is not supported by this adapter yet"
        end
      end

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

      private

      def ensure_set_initialized(key)
        @source[key.to_s] ||= Set.new
      end
    end
  end
end
