require 'flipper'
require 'active_record'

module Flipper
  module Adapters
    class ActiveRecord
      include ::Flipper::Adapter

      # Private: Do not use outside of this adapter.
      class Feature < ::ActiveRecord::Base
        self.table_name = [
          ::ActiveRecord::Base.table_name_prefix,
          "flipper_features",
          ::ActiveRecord::Base.table_name_suffix,
        ].join
      end

      # Private: Do not use outside of this adapter.
      class Gate < ::ActiveRecord::Base
        self.table_name = [
          ::ActiveRecord::Base.table_name_prefix,
          "flipper_gates",
          ::ActiveRecord::Base.table_name_suffix,
        ].join
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
        # super rarely, so it shouldn't matter in practice; additionally
        # to_a.first is used instead of first because of a Ruby 2.4/Rails 3.2.21
        # CI failure (https://travis-ci.org/jnunemaker/flipper/jobs/297274000).
        unless @feature_class.where(key: feature.key).to_a.first
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

      def get_all
        rows = ::ActiveRecord::Base.connection.select_all <<-SQL
          SELECT ff.key AS feature_key, fg.key, fg.value
          FROM #{@feature_class.table_name} ff
          LEFT JOIN #{@gate_class.table_name} fg ON ff.key = fg.feature_key
        SQL
        db_gates = rows.map { |row| Gate.new(row) }
        grouped_db_gates = db_gates.group_by(&:feature_key)
        result = Hash.new { |hash, key| hash[key] = default_config }
        features = grouped_db_gates.keys.map { |key| build_feature(key) }
        features.each do |feature|
          result[feature.key] = result_for_feature(feature, grouped_db_gates[feature.key])
        end
        result
      end

      # Public: Enables a gate for a given thing.
      #
      # feature - The Flipper::Feature for the gate.
      # gate - The Flipper::Gate to disable.
      # thing - The Flipper::Type being enabled for the gate.
      #
      # Returns true.
      def enable(feature, gate, thing)
        case gate.data_type
        when :boolean, :integer
          enable_single(feature, gate, thing)
        when :set
          enable_multi(feature, gate, thing)
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

      def enable_single(feature, gate, thing)
        @gate_class.transaction do
          @gate_class.where(feature_key: feature.key, key: gate.key).delete_all
          @gate_class.create! do |g|
            g.feature_key = feature.key
            g.key = gate.key
            g.value = thing.value.to_s
          end
        end
      end

      def enable_multi(feature, gate, thing)
        @gate_class.create! do |g|
          g.feature_key = feature.key
          g.key = gate.key
          g.value = thing.value.to_s
        end
      rescue ::ActiveRecord::RecordNotUnique
      rescue ::ActiveRecord::StatementInvalid => error
        raise unless error.message =~ /unique/i
      end

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
