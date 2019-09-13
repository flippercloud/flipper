# frozen_string_literal: true

require 'helper'
require 'flipper/adapters/active_record'
require 'flipper/spec/shared_adapter_specs'

# Turn off migration logging for specs
ActiveRecord::Migration.verbose = false

RSpec.describe Flipper::Adapters::ActiveRecord do
  subject { described_class.new }

  before(:all) do
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3',
                                            database: ':memory:')
  end

  before do
    ActiveRecord::Base.connection.execute <<-SQL
      CREATE TABLE flipper_features (
        id integer PRIMARY KEY,
        key text NOT NULL UNIQUE,
        created_at datetime NOT NULL,
        updated_at datetime NOT NULL
      )
    SQL

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE TABLE flipper_gates (
        id integer PRIMARY KEY,
        feature_key text NOT NULL,
        key text NOT NULL,
        value text DEFAULT NULL,
        created_at datetime NOT NULL,
        updated_at datetime NOT NULL
      )
    SQL

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE UNIQUE INDEX index_gates_on_keys_and_value on flipper_gates (feature_key, key, value)
    SQL
  end

  after do
    ActiveRecord::Base.connection.execute("DROP table IF EXISTS `flipper_features`")
    ActiveRecord::Base.connection.execute("DROP table IF EXISTS `flipper_gates`")
  end

  it_behaves_like 'a flipper adapter'
end
