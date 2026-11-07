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
        @sync_version = nil
        @lock = Mutex.new if threadsafe
      end

      # Public: The set of known features.
      def features
        synchronize_read { @source.keys }.to_set
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
        synchronize_read { @source[feature.key] } || DEFAULT_CONFIG
      end

      def get_multi(features)
        synchronize_read do
          result = {}
          features.each do |feature|
            result[feature.key] = @source[feature.key] || DEFAULT_CONFIG
          end
          result
        end
      end

      def get_all(**kwargs)
        synchronize_read { Typecast.features_hash(@source) }
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
        get_all = copy_features(adapter.get_all)
        synchronize do
          @source.replace(get_all)
          @sync_version = nil
        end
        true
      end

      def supports?(feature)
        feature.to_sym == :atomic_snapshot_install ? !@lock.nil? : super
      end

      def apply_snapshot(snapshot, instrumenter: Instrumenters::Noop)
        return super unless supports?(:atomic_snapshot_install)
        features = copy_features(snapshot.features)
        synchronize do
          if snapshot.version && @sync_version && snapshot.version < @sync_version
            next :stale
          end

          # Stage the diff so exceptions cannot expose partially updated gates.
          staged = Memory.new(copy_features(@source), threadsafe: false)
          result = Sync::SnapshotApplier.new(staged, features, instrumenter: instrumenter).call
          @source.replace(staged.get_all) if result == :applied
          @sync_version = snapshot.version
          result
        end
      end

      private

      def copy_features(features)
        copy_value(Typecast.features_hash(features))
      end

      def copy_value(value)
        case value
        when Hash
          value.each_with_object({}) { |(key, item), result| result[key] = copy_value(item) }
        when Set
          Set.new(value.map { |item| copy_value(item) })
        when Array
          value.map { |item| copy_value(item) }
        when String
          value.dup
        else
          value
        end
      end

      # A sync instrumenter may evaluate flags on this thread. It already owns
      # the mutex and sees the complete pre-install state, not staged writes.
      # Mutations still use synchronize and cannot re-enter installation.
      def synchronize_read(&block)
        @lock&.owned? ? yield : synchronize(&block)
      end

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
