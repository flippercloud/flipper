require 'set'
require 'flipper'
require 'active_record'

module Flipper
  module Adapters
    class ActiveRecord
      include ::Flipper::Adapter

      # Private: Do not use outside of this adapter.
      class Feature < ::ActiveRecord::Base
        self.table_name = "flipper_features"
      end

      # Private: Do not use outside of this adapter.
      class Gate < ::ActiveRecord::Base
        self.table_name = "flipper_gates"
      end

      # Public: The name of the adapter.
      attr_reader :name

      # Public: Initialize a new ActiveRecord adapter instance.
      #
      # name - The Symbol name for this adapter. Optional (default :active_record)
      # feature_class - The AR class responsible for the features table.
      # gate_class - The AR class responsible for the gates table.
      #
      # Allowing the overriding of name is so you can differentiate multiple
      # instances of this adapter from each other, if, for some reason, that is
      # a thing you do.
      #
      # Allowing the overriding of the default feature/gate classes means you
      # can roll your own tables and what not, if you so desire.
      def initialize(options = {})
        @name = options.fetch(:name, :active_record)
        @feature_class = options.fetch(:feature_class) { Feature }
        @gate_class = options.fetch(:gate_class) { Gate }
      end

      # Public: The set of known features.
      def features
        @feature_class.all.map(&:key).to_set
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        attributes = {key: feature.key}
        # race condition, but add is only used by enable/disable which happen
        # super rarely, so it shouldn't matter in practice
        @feature_class.where(attributes).first || @feature_class.create!(attributes)
        true
      end

      # Public: Removes a feature from the set of known features.
      def remove(feature)
        @feature_class.transaction do
          @feature_class.where(key: feature.key).delete_all
          clear(feature)
        end
        true
      end

      # Public: Clears the gate values for a feature.
      def clear(feature)
        @gate_class.where(feature_key: feature.key).delete_all
        true
      end

      # Public: Gets the values for all gates for a given feature.
      #
      # Returns a Hash of Flipper::Gate#key => value.
      def get(feature)
        result = {}

        db_gates = @gate_class.where(feature_key: feature.key)

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
          @gate_class.transaction do
            @gate_class.where(
              feature_key: feature.key,
              key: gate.key
            ).delete_all

            @gate_class.create!({
              feature_key: feature.key,
              key: gate.key,
              value: thing.value.to_s,
            })
          end
        when :set
          @gate_class.create!({
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
          @gate_class.transaction do
            @gate_class.where(
              feature_key: feature.key,
              key: gate.key
            ).delete_all

            @gate_class.create!({
              feature_key: feature.key,
              key: gate.key,
              value: thing.value.to_s,
            })
          end
        when :set
          @gate_class.where(feature_key: feature.key, key: gate.key, value: thing.value).delete_all
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
