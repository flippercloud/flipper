require 'test_helper'
require 'flipper/adapters/v2/active_record'
require 'generators/flipper/templates/v2_migration'

# Turn off migration logging for specs
ActiveRecord::Migration.verbose = false

class ActiveRecordTest < MiniTest::Test
  prepend Flipper::Test::V2SharedAdapterTests

  def setup
    ActiveRecord::Base.establish_connection({
      adapter: "sqlite3",
      database: ":memory:",
    })

    @adapter = Flipper::Adapters::V2::ActiveRecord.new
    CreateFlipperV2Tables.up
  end

  def teardown
    CreateFlipperV2Tables.down
  end
end
