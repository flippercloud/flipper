require 'test_helper'
require 'flipper/test/shared_adapter_test'
require 'flipper/adapters/active_record'
require 'generators/flipper/templates/migration'

# Turn off migration logging for specs
ActiveRecord::Migration.verbose = false

class ActiveRecordTest < MiniTest::Test
  prepend Flipper::Test::SharedAdapterTests

  def setup
    DataStores.reset_active_record
    @adapter = Flipper::Adapters::ActiveRecord.new
  end
end
