require 'test_helper'
require 'flipper/adapters/active_record'

# Turn off migration logging for specs
require 'generators/flipper/templates/migration'
ActiveRecord::Migration.verbose = false

class ActiveRecordTest < MiniTest::Test
  prepend SharedAdapterTests

  def setup
    ActiveRecord::Base.establish_connection({
      adapter: "sqlite3",
      database: ":memory:",
    })
    @adapter = Flipper::Adapters::ActiveRecord.new
    CreateFlipperTables.up
  end
end
