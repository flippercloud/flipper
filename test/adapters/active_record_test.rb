require 'test_helper'
require 'flipper/adapters/active_record'
require 'generators/flipper/templates/migration'

# Turn off migration logging for specs
ActiveRecord::Migration.verbose = false

class ActiveRecordTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  ActiveRecord::Base.establish_connection(adapter: 'sqlite3',
                                          database: ':memory:')

  def setup
    @adapter = Flipper::Adapters::ActiveRecord.new
    CreateFlipperTables.up
  end

  def teardown
    CreateFlipperTables.down
  end
end
