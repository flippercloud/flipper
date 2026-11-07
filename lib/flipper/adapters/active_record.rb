require 'set'
require 'securerandom'
require 'flipper'
require 'active_record'

ActiveSupport.on_load(:active_record) do
  require_relative 'active_record/model'
  require_relative 'active_record/feature'
  require_relative 'active_record/gate'
  require_relative 'active_record/sync_state'
end

module Flipper
  module Adapters
    class ActiveRecord
      include ::Flipper::Adapter

      VALUE_TO_TEXT_WARNING = <<-EOS
        Your database needs to be migrated to use the latest Flipper features.
        Run `rails generate flipper:update` and `rails db:migrate`.
      EOS

      # Public: Initialize a new ActiveRecord adapter instance.
      #
      # name - The Symbol name for this adapter. Optional (default :active_record)
      # feature_class - The AR class responsible for the features table.
      # gate_class - The AR class responsible for the gates table.
      # sync_state_class - The AR class for private snapshot revision metadata.
      # table_prefix - The prefix for the default feature, gate, and sync tables.
      #
      # Allowing the overriding of name is so you can differentiate multiple
      # instances of this adapter from each other, if, for some reason, that is
      # a thing you do.
      #
      # Allowing the overriding of the default feature/gate classes means you
      # can roll your own tables and what not, if you so desire.
      def initialize(options = {})
        @name = options.fetch(:name, :active_record)
        table_prefix = options[:table_prefix]
        @feature_class = options.fetch(:feature_class) do
          model_class(Flipper::Adapters::ActiveRecord::Feature, table_prefix, "flipper_features")
        end
        @gate_class = options.fetch(:gate_class) do
          model_class(Flipper::Adapters::ActiveRecord::Gate, table_prefix, "flipper_gates")
        end
        @sync_state_class = options.fetch(:sync_state_class) do
          model_class(Flipper::Adapters::ActiveRecord::SyncState, table_prefix, "flipper_sync_states")
        end
      end

      # Public: The set of known features.
      def features
        with_connection(@feature_class) { @feature_class.distinct.pluck(:key).to_set }
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        with_write_connection(@feature_class) do
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
        with_write_connection(@feature_class) do
          @feature_class.transaction do
            @feature_class.where(key: feature.key).destroy_all
            clear(feature)
          end
        end
        true
      end

      # Public: Clears the gate values for a feature.
      def clear(feature)
        with_write_connection(@gate_class) { @gate_class.where(feature_key: feature.key).destroy_all }
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

      def get_all(**kwargs)
        with_connection(@feature_class) do |connection|
          # query the gates from the db in a single query
          features = @feature_class.arel_table
          gates = @gate_class.arel_table
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
          result.default_proc = nil
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
          with_write_connection(@gate_class) do
            delete(feature, gate)
          end
        when :set
          with_write_connection(@gate_class) do
            @gate_class.where(feature_key: feature.key, key: gate.key, value: thing.value).destroy_all
          end
        else
          unsupported_data_type gate.data_type
        end

        true
      end

      def supports?(feature)
        return super unless feature.to_sym == :atomic_snapshot_install

        with_write_connection(@feature_class) do |connection|
          same_pool = [@gate_class, @sync_state_class].all? do |model|
            model.connection_pool.equal?(@feature_class.connection_pool)
          end
          same_pool && %w[PostgreSQL Mysql2 SQLite].include?(connection.adapter_name) &&
            @sync_state_class.table_exists?
        end
      end

      def apply_snapshot(snapshot, instrumenter: Instrumenters::Noop)
        return super unless supports?(:atomic_snapshot_install)

        with_write_connection(@feature_class) do |connection|
          if snapshot.version && connection.transaction_open?
            raise ArgumentError, "versioned snapshot installation requires its own transaction"
          end
          @feature_class.uncached do
            @feature_class.transaction(requires_new: true) do
              state = lock_sync_state
              if snapshot.version && state.version && snapshot.version < state.version
                next :stale
              end

              result = Sync::SnapshotApplier.new(self, snapshot.features, instrumenter: instrumenter).call
              state.update!(version: snapshot.version) if state.version != snapshot.version
              result
            end
          end
        end
      end

      # Explicit imports keep the released unconditional replacement semantics.
      # Their unversioned snapshot also clears the synchronization floor.
      def import(source)
        remote = Memory.new(self.class.from(source).get_all)
        Sync::Synchronizer.new(self, remote).call
        true
      end

      # Private
      def unsupported_data_type(data_type)
        raise "#{data_type} is not supported by this adapter"
      end

      private

      def lock_sync_state
        # Scope the floor to the feature/gate tables even when applications
        # share a metadata table between multiple adapter configurations.
        scope = @sync_state_class.where(key: "#{@feature_class.table_name}/#{@gate_class.table_name}")
        begin
          @sync_state_class.transaction(requires_new: true) { scope.create! }
        rescue ::ActiveRecord::RecordNotUnique
          # Roll back the savepoint before using the outer transaction again.
        end
        # SQLite has no row locks. A write before any state read serializes its
        # transactions too; PostgreSQL/MySQL take the same row lock here.
        scope.update_all(version: @sync_state_class.arel_table[:version])
        scope.lock.first!
      end

      def model_class(default_class, table_prefix, table_name)
        return default_class if table_prefix.nil?

        Class.new(default_class) do
          self.table_name = "#{table_prefix}#{table_name}"
        end
      end

      def set(feature, gate, thing, options = {})
        clear_feature = options.fetch(:clear, false)
        json_feature = options.fetch(:json, false)

        raise VALUE_TO_TEXT_WARNING if json_feature && value_not_text?

        with_write_connection(@gate_class) do
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
        with_write_connection(@gate_class) do |connection|
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
        # Bucket rows by gate key in one pass instead of re-scanning all rows
        # for each of the feature's gates. Features with many enabled actors
        # can have thousands of rows. Rows with a nil key come from the outer
        # join in get_all for features with no gate values.
        values_by_key = nil
        gates&.each do |key, value|
          next if key.nil?
          values_by_key ||= {}
          (values_by_key[key.to_sym] ||= []) << value
        end

        result = {}
        feature.gates.each do |gate|
          values = values_by_key && values_by_key[gate.key]
          result[gate.key] =
            case gate.data_type
            when :boolean, :integer
              values&.first
            when :json
              Typecast.from_json(values.first) if values
            when :set
              values ? values.to_set : Set.new
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

      def with_write_connection(model = @feature_class, &block)
        # Use Rails' built-in method to find the class that controls the connection
        # This walks up the inheritance chain to find which class called connects_to
        if model.respond_to?(:connection_class_for_self)
          connection_class = model.connection_class_for_self

          # Only use connected_to if this class actually has connects_to configured
          # connection_class? returns true when connects_to was called on the class
          if connection_class.respond_to?(:connection_class?) && connection_class.connection_class?
            connection_class.connected_to(role: :writing) do
              with_connection(model, &block)
            end
          else
            with_connection(model, &block)
          end
        else
          with_connection(model, &block)
        end
      end

      def warned_about_value_not_text?
        return @warned_about_value_not_text if defined?(@warned_about_value_not_text)

        @warned_about_value_not_text = true
        false
      end
    end
  end
end

Flipper.configure do |config|
  config.adapter { Flipper::Adapters::ActiveRecord.new }
end
