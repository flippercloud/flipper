require 'set'
require 'flipper'
require 'sequel'
require 'flipper/model/sequel'

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

      VALUE_TO_TEXT_WARNING = <<-EOS
        Your database needs to be migrated to use the latest Flipper features.
        See https://github.com/flippercloud/flipper/issues/557
      EOS

      # Public: Initialize a new Sequel adapter instance.
      #
      # name - The Symbol name for this adapter. Optional (default :sequel)
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

        warn VALUE_TO_TEXT_WARNING if value_not_text?
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

      def get_all(**kwargs)
        feature_table = @feature_class.table_name.to_sym
        gate_table = @gate_class.table_name.to_sym
        features_sql = @feature_class.select(::Sequel.qualify(feature_table, :key).as(:feature_key))
            .select_append(::Sequel.qualify(gate_table, :key))
            .select_append(::Sequel.qualify(gate_table, :value))
            .left_join(@gate_class.table_name.to_sym, feature_key: :key)
            .sql

        db_gates = @gate_class.fetch(features_sql).to_a
        grouped_db_gates = db_gates.group_by(&:feature_key)
        result = Hash.new { |hash, key| hash[key] = default_config }
        features = grouped_db_gates.keys.map { |key| Flipper::Feature.new(key, self) }
        features.each do |feature|
          result[feature.key] = result_for_feature(feature, grouped_db_gates[feature.key])
        end
        result.default_proc = nil
        result
      end

      # Public: Enables a gate for a given thing.
      #
      # feature - The Flipper::Feature for the gate.
      # gate - The Flipper::Gate to enable.
      # thing - The Flipper::Type being enabled for the gate.
      #
      # Returns true.
      def enable(feature, gate, thing)
        case gate.data_type
        when :boolean
          set(feature, gate, thing, clear: true)
        when :integer
          set(feature, gate, thing)
        when :set
          enable_multi(feature, gate, thing)
        when :json
          set(feature, gate, thing, json: true)
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
        when :json
          delete(feature, gate)
        when :set
          @gate_class.where(gate_attrs(feature, gate, thing, json: gate.data_type == :json)).delete
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
        json_feature = options.fetch(:json, false)

        raise VALUE_TO_TEXT_WARNING if json_feature && value_not_text?

        @gate_class.db.transaction do
          clear(feature) if clear_feature
          delete(feature, gate)

          begin
            @gate_class.create(gate_attrs(feature, gate, thing, json: json_feature))
          rescue ::Sequel::UniqueConstraintViolation
          end
        end
      end

      def delete(feature, gate)
        @gate_class.where(feature_key: feature.key, key: gate.key.to_s).delete
      end

      def enable_multi(feature, gate, thing)
        begin
          @gate_class.create(gate_attrs(feature, gate, thing, json: gate.data_type == :json))
        rescue ::Sequel::UniqueConstraintViolation
        end
      end

      def gate_attrs(feature, gate, thing, json: false)
        {
          feature_key: feature.key.to_s,
          key: gate.key.to_s,
          value: json ? Typecast.to_json(thing.value) : thing.value.to_s,
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
            when :json
              if detected_db_gate = db_gates.detect { |db_gate| db_gate.key == gate.key.to_s }
                Typecast.from_json(detected_db_gate.value)
              end
            else
              unsupported_data_type gate.data_type
            end
        end
      end

      # Check if value column is text instead of string
      # See https://github.com/flippercloud/flipper/pull/692
      def value_not_text?
        "text".casecmp(@gate_class.db_schema[:value][:db_type]) != 0
      end
    end
  end
end

Flipper.configure do |config|
  config.adapter { Flipper::Adapters::Sequel.new }
end

Sequel::Model.include Flipper::Model::Sequel
