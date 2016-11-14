require 'test_helper'
require 'flipper/test/v2_shared_adapter_test'
require 'flipper/adapters/v2/mongo'

class V2MongoTest < MiniTest::Test
  prepend Flipper::Test::V2SharedAdapterTests

  def setup
    DataStores.reset_mongo
    @adapter = Flipper::Adapters::V2::Mongo.new(DataStores.mongo)
  end
end
