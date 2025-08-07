require 'set'
require 'securerandom'
require 'flipper'
require 'active_record'

module Flipper
  module Adapters
    class ActiveRecord
      include ::Flipper::Adapter

      ActiveSupport.on_load(:active_record) do
        class Model < ::ActiveRecord::Base
          self.abstract_class = true
        end

        # Private: Do not use outside of this adapter.
        class Feature < Model
          self.table_name = [
            Model.table_name_prefix,
            "flipper_features",
            Model.table_name_suffix,
          ].join

          has_many :gates, foreign_key: "feature_key", primary_key: "key"

          validates :key, presence: true
        end

        # Private: Do not use outside of this adapter.
        class Gate < Model
          self.table_name = [
            Model.table_name_prefix,
            "flipper_gates",
            Model.table_name_suffix,
          ].join

          validates :feature_key, presence: true
          validates :key, presence: true
        end
      end

      VALUE_TO_TEXT_WARNING = <<-EOS
        Your database needs to be migrated to use the latest Flipper features.
        Run `rails generate flipper:update` and `rails db:migrate`.
      EOS

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
        @feature_class = options.fetch(:feature_class) { Flipper::Adapters::ActiveRecord::Feature }
        @gate_class = options.fetch(:gate_class) { Flipper::Adapters::ActiveRecord::Gate }
      end

      # Public: The set of known features.
      def features
        with_connection(@feature_class) { @feature_class.distinct.pluck(:key).to_set }
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        with_connection(@feature_class) do
          @feature_class.transaction(requires_new: true) do
            begin
              # race condition, but add is only used by enable/disable which happen
              # super rarely, so it shouldn't matter in practice
              unless @feature_class.where(key: feature.key).exists?
                @feature_class.create!(key: feature.key)
              end
            rescue ::ActiveRecord::RecordNotUnique
              # already added
            end
          end
        end

        true
      end

      # Public: Removes a feature from the set of known features.
      def remove(feature)
        with_connection(@feature_class) do
          @feature_class.transaction do
            @feature_class.where(key: feature.key).destroy_all
            clear(feature)
          end
        end
        true
      end

      # Public: Clears the gate values for a feature.
      def clear(feature)
        with_connection(@gate_class) { @gate_class.where(feature_key: feature.key).destroy_all }
        true
      end

      # Public: Gets the values for all gates for a given feature.
      #
      # Returns a Hash of Flipper::Gate#key => value.
      def get(feature)
        gates = with_connection(@gate_class) { @gate_class.where(feature_key: feature.key).pluck(:key, :value) }
        result_for_gates(feature, gates)
      end

      def get_multi(features)
        with_connection(@gate_class) do
          gates = @gate_class.where(feature_key: features.map(&:key)).pluck(:feature_key, :key, :value)
          grouped_gates = gates.inject({}) do |hash, (feature_key, key, value)|
            hash[feature_key] ||= []
            hash[feature_key] << [key, value]
            hash
          end

          result = {}
          features.each do |feature|
            result[feature.key] = result_for_gates(feature, grouped_gates[feature.key])
          end
          result
        end
      end

      def get_all
        with_connection(@feature_class) do |connection|
          # query the gates from the db in a single query
          features = ::Arel::Table.new(@feature_class.table_name.to_sym)
          gates = ::Arel::Table.new(@gate_class.table_name.to_sym)
          rows_query = features.join(gates, ::Arel::Nodes::OuterJoin)
            .on(features[:key].eq(gates[:feature_key]))
            .project(features[:key].as('feature_key'), gates[:key], gates[:value])
          gates = connection.select_rows(rows_query)

          # group the gates by feature key
          grouped_gates = gates.inject({}) do |hash, (feature_key, key, value)|
            hash[feature_key] ||= []
            hash[feature_key] << [key, value]
            hash
          end

          # build up the result hash
          result = Hash.new { |hash, key| hash[key] = default_config }
          features = grouped_gates.keys.map { |key| Flipper::Feature.new(key, self) }
          features.each do |feature|
            result[feature.key] = result_for_gates(feature, grouped_gates[feature.key])
          end
          result
        end
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
        when :json
          set(feature, gate, thing, json: true)
        when :set
          enable_multi(feature, gate, thing)
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
          with_connection(@gate_class) do
            @gate_class.where(feature_key: feature.key, key: gate.key, value: thing.value).destroy_all
          end
        else
          unsupported_data_type gate.data_type
        end

        true
      end

      # Private
      def unsupported_data_type(data_type)
        raise "#{data_type} is not supported by this adapter"
      end

      private

      def set(feature, gate, thing, options = {})
        clear_feature = options.fetch(:clear, false)
        json_feature = options.fetch(:json, false)

        raise VALUE_TO_TEXT_WARNING if json_feature && value_not_text?

        with_connection(@gate_class) do
          @gate_class.transaction(requires_new: true) do
            clear(feature) if clear_feature
            delete(feature, gate)
            begin
              @gate_class.create! do |g|
                g.feature_key = feature.key
                g.key = gate.key
                g.value = json_feature ? Typecast.to_json(thing.value) : thing.value.to_s
              end
            rescue ::ActiveRecord::RecordNotUnique
              # assume this happened concurrently with the same thing and its fine
              # see https://github.com/flippercloud/flipper/issues/544
            end
          end
        end

        nil
      end

      def delete(feature, gate)
        @gate_class.where(feature_key: feature.key, key: gate.key).destroy_all
      end

      def enable_multi(feature, gate, thing)
        with_connection(@gate_class) do |connection|
          begin
            connection.transaction(requires_new: true) do
              @gate_class.create! do |g|
                g.feature_key = feature.key
                g.key = gate.key
                g.value = thing.value.to_s
              end
            end
          rescue ::ActiveRecord::RecordNotUnique
            # already added so move on with life
          end
        end

        nil
      end

      def result_for_gates(feature, gates)
        result = {}
        gates ||= []
        feature.gates.each do |gate|
          result[gate.key] =
            case gate.data_type
            when :boolean, :integer
              if row = gates.detect { |key, value| !key.nil? && key.to_sym == gate.key }
                row.last
              end
            when :json
              if row = gates.detect { |key, value| !key.nil? && key.to_sym == gate.key }
                Typecast.from_json(row.last)
              end
            when :set
              gates.select { |key, value| !key.nil? && key.to_sym == gate.key }.map(&:last).to_set
            else
              unsupported_data_type gate.data_type
            end
        end
        result
      end

      # Check if value column is text instead of string
      # See https://github.com/flippercloud/flipper/pull/692
      def value_not_text?
        with_connection(@gate_class) do |connection|
          @gate_class.column_for_attribute(:value).type != :text
        end
      rescue ::ActiveRecord::ActiveRecordError => error
        # If the table doesn't exist, the column doesn't exist either
        warn "#{error.message}. You likely need to run `rails g flipper:active_record` and/or `rails db:migrate`."
      end

      def with_connection(model = @feature_class, &block)
        warn VALUE_TO_TEXT_WARNING if !warned_about_value_not_text? && value_not_text?
        model.connection_pool.with_connection(&block)
      end

      def warned_about_value_not_text?
        return @warned_about_value_not_text if defined?(@warned_about_value_not_text)
        @warned_about_value_not_text = true
      end
    end
  end
end

Flipper.configure do |config|
  config.adapter { Flipper::Adapters::ActiveRecord.new }
end
