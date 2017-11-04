require 'rails/generators/active_record'

module Flipper
  module Generators
    class ActiveRecordGenerator < ::Rails::Generators::Base
      include ::Rails::Generators::Migration
      desc 'Generates migration for flipper tables'

      source_paths << File.join(File.dirname(__FILE__), 'templates')

      def self.next_migration_number(dirname)
        ::ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def self.migration_version
        if Rails.version.start_with?('5')
          "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
        end
      end

      def create_migration_file
        migration_template 'migration.rb', 'db/migrate/create_flipper_tables.rb', migration_version: migration_version
      end

      def migration_version
        self.class.migration_version
      end
    end
  end
end
