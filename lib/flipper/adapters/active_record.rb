require 'set'
require 'flipper'
require 'active_record'

module Flipper
  module Adapters
    class ActiveRecord
      include Flipper::Adapter

      class Feature < ::ActiveRecord::Base
        self.table_name = "flipper_features"
      end

      class Gate < ::ActiveRecord::Base
        self.table_name = "flipper_gates"
      end

      # Public: The name of the adapter.
      attr_reader :name

      def initialize
        @name = :active_record
      end

      # Public: The set of known features.
      def features
        Feature.select(:key).map(&:key).to_set
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        attributes = {key: feature.key}
        # race condition, but add is only used by enable/disable which happen
        # super rarely, so it shouldn't matter in practice
        Feature.where(attributes).first || Feature.create!(attributes)
        true
      end

      # Public: Removes a feature from the set of known features.
      def remove(feature)
        Feature.transaction do
          Feature.delete_all(key: feature.key)
          clear(feature)
        end
        true
      end

      # Public: Clears the gate values for a feature.
      def clear(feature)
        Gate.delete_all(feature_key: feature.key)
        true
      end

      # Public: Gets the values for all gates for a given feature.
      #
      # Returns a Hash of Flipper::Gate#key => value.
      def get(feature)
        result = {}

        db_gates = Gate.where(feature_key: feature.key)

        feature.gates.each do |gate|
          result[gate.key] = case gate.data_type
          when :boolean
            if db_gate = db_gates.detect { |db_gate| db_gate.key == gate.key.to_s }
              db_gate.value
            end
          when :integer
            if db_gate = db_gates.detect { |db_gate| db_gate.key == gate.key.to_s }
              db_gate.value
            end
          when :set
            db_gates.select { |db_gate| db_gate.key == gate.key.to_s }.map(&:value).to_set
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
          Gate.create!({
            feature_key: feature.key,
            key: gate.key,
            value: thing.value.to_s,
          })
        when :set
          Gate.create!({
            feature_key: feature.key,
            key: gate.key,
            value: thing.value.to_s,
          })
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
          clear(feature)
        when :integer
          Gate.create!({
            feature_key: feature.key,
            key: gate.key,
            value: thing.value.to_s,
          })
        when :set
          Gate.delete_all(feature_key: feature.key, key: gate.key, value: thing.value)
        else
          unsupported_data_type gate.data_type
        end

        true
      end

      # Private
      def unsupported_data_type(data_type)
        raise "#{data_type} is not supported by this adapter"
      end
    end
  end
end
