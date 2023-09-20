require "flipper/adapter"
require "flipper/typecast"

module Flipper
  module Adapters
    # Public: Adapter for storing everything in memory.
    # Useful for tests/specs.
    class Memory
      include ::Flipper::Adapter

      # Public
      def initialize(source = nil, threadsafe: true)
        @source = Typecast.features_hash(source)
        @lock = Mutex.new if threadsafe
        reset
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
        synchronize { @source[feature.key] } || default_config
      end

      def get_multi(features)
        synchronize do
          result = {}
          features.each do |feature|
            result[feature.key] = @source[feature.key] || default_config
          end
          result
        end
      end

      def get_all
        synchronize { Typecast.features_hash(@source) }
      end

      # Public
      def enable(feature, gate, thing)
        synchronize do
          @source[feature.key] ||= default_config

          case gate.data_type
          when :boolean
            @source[feature.key] = default_config
            @source[feature.key][gate.key] = thing.value.to_s
          when :integer
            @source[feature.key][gate.key] = thing.value.to_s
          when :set
            @source[feature.key][gate.key] << thing.value.to_s
          when :json
            @source[feature.key][gate.key] = thing.value
          else
            raise "#{gate} is not supported by this adapter yet"
          end

          true
        end
      end

      # Public
      def disable(feature, gate, thing)
        synchronize do
          @source[feature.key] ||= default_config

          case gate.data_type
          when :boolean
            @source[feature.key] = default_config
          when :integer
            @source[feature.key][gate.key] = thing.value.to_s
          when :set
            @source[feature.key][gate.key].delete thing.value.to_s
          when :json
            @source[feature.key].delete(gate.key)
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
        synchronize { @source.replace(get_all) }
        true
      end

      private

      def reset
        @pid = Process.pid
        @lock&.unlock if @lock&.locked?
      end

      def forked?
        @pid != Process.pid
      end

      def synchronize(&block)
        if @lock
          reset if forked?
          @lock.synchronize(&block)
        else
          block.call
        end
      end
    end
  end
end
