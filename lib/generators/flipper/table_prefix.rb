require 'active_support/core_ext/string/inflections'

module Flipper
  module Generators
    module TablePrefix
      def self.included(generator)
        generator.class_option :table_prefix,
                               type: :string,
                               default: '',
                               desc: 'Prefix for the flipper_features and flipper_gates tables'
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

      def migration_class_name(class_name)
        class_name.sub('Flipper', "#{table_prefix.camelize}Flipper")
      end

      def table_prefix
        options[:table_prefix].to_s
      end
    end
  end
end
