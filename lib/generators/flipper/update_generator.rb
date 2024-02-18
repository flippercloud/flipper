# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'

module Flipper
  module Generators
    #
    # Rails generator used for updating Flipper in a Rails application.
    # Run it with +bin/rails g flipper:update+ in your console.
    #
    class UpdateGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      TEMPLATES = File.join(File.dirname(__FILE__), 'templates/update')
      source_paths << TEMPLATES

      # Generates incremental migration files unless they already exist.
      # All migrations should be idempotent e.g. +add_index+ is guarded with +if_index_exists?+
      def update_migration_files
        migration_templates = Dir.children(File.join(TEMPLATES, 'migrations')).sort
        migration_templates.each do |template_file|
          destination_file = template_file.match(/^\d*_(.*\.rb)/)[1] # 01_create_flipper_tables.rb.erb => create_flipper_tables.rb
          migration_template "migrations/#{template_file}", File.join(db_migrate_path, destination_file), skip: true
        end
      end

      private

      def migration_version
        "[#{ActiveRecord::VERSION::STRING.to_f}]"
      end
    end
  end
end
