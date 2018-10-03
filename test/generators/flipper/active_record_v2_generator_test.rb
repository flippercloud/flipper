require_relative '../../test_helper'
require 'active_record'
require 'rails/generators/test_case'
require 'generators/flipper/active_record_v2_generator'

class FlipperActiveRecordV2GeneratorTest < Rails::Generators::TestCase
  tests Flipper::Generators::ActiveRecordV2Generator
  destination File.expand_path("../../../../tmp", __FILE__)
  setup :prepare_destination

  def test_generates_migration
    run_generator
    migration_version = if Rails::VERSION::MAJOR.to_i < 5
                          ""
                        else
                          "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
                        end
    assert_migration "db/migrate/create_flipper_keys_table.rb", <<-EOM
class CreateFlipperV2Tables < ActiveRecord::Migration#{migration_version}
  def self.up
    create_table :flipper_keys do |t|
      t.string :key, null: false
      t.binary :value, null: false
      t.timestamps null: false
    end
    add_index :flipper_keys, :key, unique: true
  end

  def self.down
    drop_table :flipper_keys
  end
end
EOM
  end
end
