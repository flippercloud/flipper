require 'helper'
require 'flipper/adapters/active_record'
require 'flipper/spec/shared_adapter_specs'

# Turn off migration logging for specs
ActiveRecord::Migration.verbose = false

class CreateFlipperTables < ActiveRecord::Migration
  def self.up
    create_table :flipper_features do |t|
      t.string :key, null: false
      t.timestamps null: false
    end
    add_index :flipper_features, :key, unique: true

    create_table :flipper_gates do |t|
      t.string :feature_key, null: false
      t.string :key, null: false
      t.string :value
      t.timestamps null: false
    end
    add_index :flipper_gates, [:feature_key, :key, :value], unique: true
  end

  def self.down
    drop_table :flipper_gates
    drop_table :flipper_features
  end
end

RSpec.describe Flipper::Adapters::ActiveRecord do
  subject { described_class.new }

  before(:all) do
    ActiveRecord::Base.establish_connection({
      adapter: "sqlite3",
      database: ":memory:",
    })
  end

  before(:each) do
    CreateFlipperTables.up
  end

  after(:each) do
    CreateFlipperTables.down
  end

  it_should_behave_like 'a flipper adapter'
end
