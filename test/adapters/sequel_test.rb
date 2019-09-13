require 'test_helper'
require 'sequel'

Sequel::Model.db = Sequel.sqlite(':memory:')
Sequel.extension :migration, :core_extensions

require 'flipper/adapters/sequel'
require 'generators/flipper/templates/sequel_migration'

class SequelTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  def feature_class
    Flipper::Adapters::Sequel::Feature
  end

  def gate_class
    Flipper::Adapters::Sequel::Gate
  end

  def setup
    CreateFlipperTablesSequel.new(Sequel::Model.db).up
    feature_class.dataset = feature_class.dataset
    gate_class.dataset = gate_class.dataset
    @adapter = Flipper::Adapters::Sequel.new
  end

  def teardown
    CreateFlipperTablesSequel.new(Sequel::Model.db).down
  end
end
