require "pstore"
require "set"

module Flipper
  module Adapters
    # Public: Adapter based on Ruby's pstore database. Perfect for when a local
    # file is good enough for storing features.
    class PStore
      include ::Flipper::Adapter

      FeaturesKey = :flipper_features

      # Public: The name of the adapter.
      attr_reader :name

      # Public: The path to where the file is stored.
      attr_reader :path

      def initialize(path = "flipper.pstore")
        @path = path
        @store = ::PStore.new(path)
        @name = :pstore
      end

      def features
        set_members FeaturesKey
      end

      def add(feature)
        set_add FeaturesKey, feature.key
        true
      end

      def remove(feature)
        set_delete FeaturesKey, feature.key
        clear(feature)
        true
      end

      def clear(feature)
        feature.gates.each do |gate|
          delete key(feature, gate)
        end
        true
      end

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

      def inspect
        attributes = [
          "name=#{@name.inspect}",
          "path=#{@path.inspect}",
          "store=#{@store}",
        ]
        "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
      end

      private

      def key(feature, gate)
        "#{feature.key}/#{gate.key}"
      end

      def read(key)
        @store.transaction do
          @store[key.to_s]
        end
      end

      def write(key, value)
        @store.transaction do
          @store[key.to_s] = value.to_s
        end
      end

      def delete(key)
        @store.transaction do
          @store.delete(key.to_s)
        end
      end

      def set_add(key, value)
        set_members(key) do |members|
          members.add(value.to_s)
        end
      end

      def set_delete(key, value)
        set_members(key) do |members|
          members.delete(value.to_s)
        end
      end

      def set_members(key)
        key = key.to_s
        @store.transaction do
          @store[key] ||= Set.new

          if block_given?
            yield @store[key]
          else
            @store[key]
          end
        end
      end
    end
  end
end
