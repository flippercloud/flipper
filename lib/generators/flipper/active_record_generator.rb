require 'rails/generators/active_record'
require 'rails/version'

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
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]" if rails5?
      end

      def self.rails5?
        Rails.respond_to?(:version) && Rails.version.start_with?('5')
      end

      def create_migration_file
        options = {
          migration_version: migration_version,
        }
        migration_template 'migration.erb', 'db/migrate/create_flipper_tables.rb', options
      end

      def migration_version
        self.class.migration_version
      end
    end
  end
end
