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
            read gate.adapter_key
          when :integer
            read gate.adapter_key
          when :set
            set_members gate.adapter_key
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
          write gate.adapter_key, thing.value.to_s
        when :set
          set_add gate.adapter_key, thing.value.to_s
        else
          raise "#{gate} is not supported by this adapter yet"
        end
      end

      # Public
      def disable(feature, gate, thing)
        case gate.data_type
        when :boolean
          # FIXME: Need to make boolean gate not need to delete everything
          feature.gates.each do |gate|
            delete gate.adapter_key
          end
        when :integer
          write gate.adapter_key, 0
        when :set
          set_delete gate.adapter_key, thing.value.to_s
        else
          raise "#{gate} is not supported by this adapter yet"
        end
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
