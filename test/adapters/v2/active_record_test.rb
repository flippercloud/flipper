require 'test_helper'
require 'flipper/test/v2_shared_adapter_test'
require 'flipper/adapters/v2/active_record'

class V2ActiveRecordTest < MiniTest::Test
  prepend Flipper::Test::V2SharedAdapterTests

  def setup
    DataStores.reset_active_record
    @adapter = Flipper::Adapters::V2::ActiveRecord.new
  end
end
