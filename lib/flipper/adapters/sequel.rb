require 'set'
require 'flipper'
require 'sequel'

module Flipper
  module Adapters
    class Sequel
      include ::Flipper::Adapter

      begin
        old = ::Sequel::Model.require_valid_table
        ::Sequel::Model.require_valid_table = false

        # Private: Do not use outside of this adapter.
        class Feature < ::Sequel::Model(:flipper_features)
          unrestrict_primary_key

          plugin :timestamps, update_on_create: true
        end

        # Private: Do not use outside of this adapter.
        class Gate < ::Sequel::Model(:flipper_gates)
          unrestrict_primary_key

          plugin :timestamps, update_on_create: true
        end
      ensure
        ::Sequel::Model.require_valid_table = old
      end

      # Public: The name of the adapter.
      attr_reader :name

      # Public: Initialize a new Sequel adapter instance.
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
        @name = options.fetch(:name, :sequel)
        @feature_class = options.fetch(:feature_class) { Feature }
        @gate_class = options.fetch(:gate_class) { Gate }
      end

      # Public: The set of known features.
      def features
        @feature_class.all.map(&:key).to_set
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        # race condition, but add is only used by enable/disable which happen
        # super rarely, so it shouldn't matter in practice
        @feature_class.find_or_create(key: feature.key.to_s)
        true
      end

      # Public: Removes a feature from the set of known features.
      def remove(feature)
        @feature_class.db.transaction do
          @feature_class.where(key: feature.key.to_s).delete
          clear(feature)
        end
        true
      end

      # Public: Clears the gate values for a feature.
      def clear(feature)
        @gate_class.where(feature_key: feature.key.to_s).delete
        true
      end

      # Public: Gets the values for all gates for a given feature.
      #
      # Returns a Hash of Flipper::Gate#key => value.
      def get(feature)
        db_gates = @gate_class.where(feature_key: feature.key.to_s).all

        result_for_feature(feature, db_gates)
      end

      def get_multi(features)
        db_gates = @gate_class.where(feature_key: features.map(&:key)).to_a
        grouped_db_gates = db_gates.group_by(&:feature_key)
        result = {}
        features.each do |feature|
          result[feature.key] = result_for_feature(feature, grouped_db_gates[feature.key])
        end
        result
      end

      def get_all
        db_gates = @gate_class.fetch(<<-SQL).to_a
          SELECT ff.key AS feature_key, fg.key, fg.value
          FROM #{@feature_class.table_name} ff
          LEFT JOIN #{@gate_class.table_name} fg ON ff.key = fg.feature_key
        SQL
        grouped_db_gates = db_gates.group_by(&:feature_key)
        result = Hash.new { |hash, key| hash[key] = default_config }
        features = grouped_db_gates.keys.map { |key| Flipper::Feature.new(key, self) }
        features.each do |feature|
          result[feature.key] = result_for_feature(feature, grouped_db_gates[feature.key])
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
        when :boolean
          set(feature, gate, thing, clear: true)
        when :integer
          set(feature, gate, thing)
        when :set
          begin
            @gate_class.create(gate_attrs(feature, gate, thing))
          rescue ::Sequel::UniqueConstraintViolation
          end
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
          set(feature, gate, thing)
        when :set
          @gate_class.where(gate_attrs(feature, gate, thing))
                     .delete
        else
          unsupported_data_type gate.data_type
        end

        true
      end

      private

      def unsupported_data_type(data_type)
        raise "#{data_type} is not supported by this adapter"
      end

      def set(feature, gate, thing, options = {})
        clear_feature = options.fetch(:clear, false)
        args = {
          feature_key: feature.key,
          key: gate.key.to_s,
        }

        @gate_class.db.transaction do
          clear(feature) if clear_feature
          @gate_class.where(args).delete
          @gate_class.create(gate_attrs(feature, gate, thing))
        end
      end

      def gate_attrs(feature, gate, thing)
        {
          feature_key: feature.key.to_s,
          key: gate.key.to_s,
          value: thing.value.to_s,
        }
      end

      def result_for_feature(feature, db_gates)
        db_gates ||= []
        feature.gates.each_with_object({}) do |gate, result|
          result[gate.key] =
            case gate.data_type
            when :boolean
              if detected_db_gate = db_gates.detect { |db_gate| db_gate.key == gate.key.to_s }
                detected_db_gate.value
              end
            when :integer
              if detected_db_gate = db_gates.detect { |db_gate| db_gate.key == gate.key.to_s }
                detected_db_gate.value
              end
            when :set
              db_gates.select { |db_gate| db_gate.key == gate.key.to_s }.map(&:value).to_set
            else
              unsupported_data_type gate.data_type
            end
        end
      end
    end
  end
end

Flipper.configure do |config|
  config.adapter { Flipper::Adapters::Sequel.new }
end

Sequel::Model.include Flipper::Identifier
