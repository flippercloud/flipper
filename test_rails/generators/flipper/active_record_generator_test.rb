require 'helper'
require 'generators/flipper/active_record_generator'

class FlipperActiveRecordGeneratorTest < Rails::Generators::TestCase
  tests Flipper::Generators::ActiveRecordGenerator
  destination File.expand_path('../../../../tmp', __FILE__)
  setup :prepare_destination

  def test_generates_migration
    run_generator
    migration_version = if Rails::VERSION::MAJOR.to_i < 5
                          ""
                        else
                          "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
                        end
    assert_migration 'db/migrate/create_flipper_tables.rb', <<~MIGRATION
      class CreateFlipperTables < ActiveRecord::Migration#{migration_version}
        def up
          create_table :flipper_features do |t|
            t.string :key, null: false
            t.timestamps null: false
          end
          add_index :flipper_features, :key, unique: true

          create_table :flipper_gates do |t|
            t.string :feature_key, null: false
            t.string :key, null: false
            t.text :value
            t.timestamps null: false
          end
          add_index :flipper_gates, [:feature_key, :key, :value], unique: true, length: { value: 255 }
        end

        def down
          drop_table :flipper_gates
          drop_table :flipper_features
        end
      end
    MIGRATION
  end

  def test_generates_migration_with_table_prefix
    run_generator ["--table-prefix=cross_product_"]
    migration_version = if Rails::VERSION::MAJOR.to_i < 5
                          ""
                        else
                          "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
                        end
    assert_migration 'db/migrate/create_cross_product_flipper_tables.rb', <<~MIGRATION
      class CreateCrossProductFlipperTables < ActiveRecord::Migration#{migration_version}
        def up
          create_table :cross_product_flipper_features do |t|
            t.string :key, null: false
            t.timestamps null: false
          end
          add_index :cross_product_flipper_features, :key, unique: true, name: :index_cross_product_flipper_features_on_key

          create_table :cross_product_flipper_gates do |t|
            t.string :feature_key, null: false
            t.string :key, null: false
            t.text :value
            t.timestamps null: false
          end
          add_index :cross_product_flipper_gates, [:feature_key, :key, :value], unique: true, length: { value: 255 }, name: :index_cross_product_flipper_gates_on_keys
        end

        def down
          drop_table :cross_product_flipper_gates
          drop_table :cross_product_flipper_features
        end
      end
    MIGRATION
  end
end
