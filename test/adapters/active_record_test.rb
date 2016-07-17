require 'test_helper'
require 'flipper/test/shared_adapter_test'
require 'flipper/adapters/active_record'
require 'generators/flipper/templates/migration'

# Turn off migration logging for specs
ActiveRecord::Migration.verbose = false

class ActiveRecordTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  def setup
    ActiveRecord::Base.establish_connection({
      adapter: "sqlite3",
      database: ":memory:",
    })

    @adapter = Flipper::Adapters::ActiveRecord.new
    CreateFlipperTables.up
  end

  def teardown
    CreateFlipperTables.down
  end
end
