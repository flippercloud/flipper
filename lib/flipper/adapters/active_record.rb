require 'flipper'
require 'active_record'

module Flipper
  module Adapters
    class ActiveRecord
      include ::Flipper::Adapter

      # Private: Do not use outside of this adapter.
      class Feature < ::ActiveRecord::Base
        self.table_name = 'flipper_features'
      end

      # Private: Do not use outside of this adapter.
      class Gate < ::ActiveRecord::Base
        self.table_name = 'flipper_gates'
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

      def features
        @feature_class.all.map(&:key).to_set
      end

      def add(feature)
        # race condition, but add is only used by enable/disable which happen
        # super rarely, so it shouldn't matter in practice
        unless @feature_class.where(key: feature.key).first
          @feature_class.create! { |f| f.key = feature.key }
        end
        true
      end

      def remove(feature)
        @feature_class.transaction do
          @feature_class.where(key: feature.key).delete_all
          clear(feature)
        end
        true
      end

      def clear(feature)
        @gate_class.where(feature_key: feature.key).delete_all
        true
      end

      def get(feature)
        db_gates = @gate_class.where(feature_key: feature.key)
        result_for_feature(feature, db_gates)
      end

      def get_multi(features)
        db_gates = @gate_class.where(feature_key: features.map(&:key))
        grouped_db_gates = db_gates.group_by(&:feature_key)
        result = {}
        features.each do |feature|
          result[feature.key] = result_for_feature(feature, grouped_db_gates[feature.key])
        end
        result
      end

      def enable(feature, gate, thing)
        case gate.data_type
        when :boolean, :integer
          @gate_class.transaction do
            @gate_class.where(
              feature_key: feature.key,
              key: gate.key
            ).delete_all

            @gate_class.create! do |g|
              g.feature_key = feature.key
              g.key = gate.key
              g.value = thing.value.to_s
            end
          end
        when :set
          @gate_class.create! do |g|
            g.feature_key = feature.key
            g.key = gate.key
            g.value = thing.value.to_s
          end
        else
          unsupported_data_type gate.data_type
        end

        true
      end

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

            @gate_class.create! do |g|
              g.feature_key = feature.key
              g.key = gate.key
              g.value = thing.value.to_s
            end
          end
        when :set
          @gate_class.where(feature_key: feature.key, key: gate.key, value: thing.value).delete_all
        else
          unsupported_data_type gate.data_type
        end

        true
      end

      private

      def unsupported_data_type(data_type)
        raise "#{data_type} is not supported by this adapter"
      end

      private

      def result_for_feature(feature, db_gates)
        db_gates ||= []
        result = {}
        feature.gates.each do |gate|
          result[gate.key] =
            case gate.data_type
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
    end
  end
end
