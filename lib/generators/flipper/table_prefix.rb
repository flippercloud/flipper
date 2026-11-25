require 'active_support/core_ext/string/inflections'

module Flipper
  module Generators
    module TablePrefix
      # Lowercase so the migration file name matches what Rails' migrator accepts.
      FORMAT = /\A[a-z0-9_]*\z/

      def self.included(generator)
        generator.class_option :table_prefix,
                               type: :string,
                               default: '',
                               desc: 'Prefix for the flipper_features and flipper_gates tables, such as cross_app_ (lowercase letters, numbers and underscores)'
      end

      private

      def feature_table_name
        :"#{table_prefix}flipper_features"
      end

      def gate_table_name
        :"#{table_prefix}flipper_gates"
      end

      def prefixed_migration_file_name(file_name)
        file_name.sub('flipper', "#{table_prefix}flipper")
      end

      def feature_index_name
        :"index_#{table_prefix}flipper_features_on_key" unless table_prefix.empty?
      end

      def gate_index_name
        :"index_#{table_prefix}flipper_gates_on_keys" unless table_prefix.empty?
      end

      def table_prefix
        prefix = options[:table_prefix].to_s
        unless FORMAT.match?(prefix)
          raise Thor::Error, "--table-prefix must contain only lowercase letters, numbers and underscores (got #{prefix.inspect})"
        end
        prefix
      end
    end
  end
end
